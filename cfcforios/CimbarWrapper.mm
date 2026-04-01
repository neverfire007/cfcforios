#import "CimbarWrapper.h"
#import <Accelerate/Accelerate.h>

// 消除 Objective-C 的 NO 宏，避免和 OpenCV 等 C++ 库内的 enum NO 冲突
#ifdef NO
#undef NO
#endif

#include <vector>
#include <string>
#include <fstream>

// libcimbar 核心头文件
#include "cimb_translator/Config.h"
#include "extractor/Extractor.h"
#include "encoder/Decoder.h"
#include "fountain/fountain_decoder_sink.h"

// OpenCV
#include <opencv2/opencv.hpp>
#include <opencv2/core.hpp>
#include <opencv2/imgproc.hpp>

// ZSTD (来自 libcimbar 的 third_party_lib)
#include "zstd/zstd.h"

@interface CimbarWrapper () {
    fountain_decoder_sink* _sink;
    std::string _outputDir;
}
@end

@implementation CimbarWrapper

- (instancetype)init {
    self = [super init];
    if (self) {
        // 找到 iOS 的 Documents 目录用于存储解码后的文件
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docDir = [paths firstObject];
        NSString *cimbarDir = [docDir stringByAppendingPathComponent:@"cimbar_output"];
        
        // 确保输出目录存在
        [[NSFileManager defaultManager] createDirectoryAtPath:cimbarDir
                                  withIntermediateDirectories:YES
                                                  attributes:nil
                                                       error:nil];
        _outputDir = std::string([cimbarDir UTF8String]);

        // FORCE B-mode (6144 = high density mode)
        cimbar::Config::update(6144);

        // 参考安卓 cfc 源码: 使用 decompress_on_store<std::ofstream> 回调。
        _sink = new fountain_decoder_sink(
            cimbar::Config::fountain_chunk_size(),
            decompress_on_store<std::ofstream>(_outputDir, true)
        );
    }
    return self;
}

- (void)dealloc {
    delete _sink;
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}

- (void)reset {
    delete _sink;
    // FORCE B-mode (6144 = high density mode)
    cimbar::Config::update(6144);
    _sink = new fountain_decoder_sink(
        cimbar::Config::fountain_chunk_size(),
        decompress_on_store<std::ofstream>(_outputDir, true)
    );
}

- (double)getProgress {
    if (!_sink) return 0.0;
    std::vector<double> progress = _sink->get_progress();
    if (progress.empty()) return 0.0;

    double maxProgress = 0.0;
    for (double p : progress) {
        if (p > maxProgress) maxProgress = p;
    }
    return maxProgress;
}

- (void)setMode:(int)mode {
    cimbar::Config::update(mode);
}

- (nullable NSData *)decode:(CVPixelBufferRef)pixelBuffer fileName:(NSString* _Nullable * _Nullable)outFileName {
    CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    void *baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);

    // 1. 转为 OpenCV 矩阵 (iOS 相机输出通常是 BGRA)
    cv::Mat bgra(height, width, CV_8UC4, baseAddress, bytesPerRow);

    // 2. 转换为 RGB，这是 Cimbar Extractor 的默认期望色彩空间
    cv::Mat rgb;
    cv::cvtColor(bgra, rgb, cv::COLOR_BGRA2RGB);

    // 3. FIX ORIENTATION: iOS相机输出默认方向不对
    // 试逆时针旋转 90度，很多设备是这个方向
    cv::Mat rotated;
    cv::rotate(rgb, rotated, cv::ROTATE_90_COUNTERCLOCKWISE);

    CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);

    cv::UMat umat = rotated.getUMat(cv::ACCESS_RW).clone();

    // FORCE B-mode (6144 high density mode), NO auto-detection
    cimbar::Config::update(6144);

    // 4. Extract grid
    Extractor extractor;
    int res = extractor.extract(umat, umat);

    if (!res) {
        return nil;
    }

    bool shouldPreprocess = (res == Extractor::NEEDS_SHARPEN);

    // 5. Decode symbols
    Decoder decoder;
    decoder.decode_fountain(umat, *_sink, shouldPreprocess);

    // 5. 检查是否有新完成的文件
    std::vector<std::string> done_files = _sink->get_done();
    if (!done_files.empty()) {
        std::string lastFile = done_files.back();
        std::string fullPath = _outputDir + "/" + lastFile;

        NSString *path = [NSString stringWithUTF8String:fullPath.c_str()];
        NSData *fileData = [NSData dataWithContentsOfFile:path];

        if (fileData) {
            if (outFileName) {
                *outFileName = [NSString stringWithUTF8String:lastFile.c_str()];
            }
            return fileData;
        }
    }

    return nil;
}

@end
