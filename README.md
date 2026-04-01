## 🏆 致谢 / Acknowledgments

本项目是基于以下优秀开源项目的 iOS 实现。诚挚感谢原作者的卓越工作与启发。
This project is an iOS implementation built upon the following remarkable open-source works. Sincere thanks to the original authors for their vision and contributions.

### 📚 技术渊源 / Inspiration & Core Technology

* **[cimbar](https://github.com/sz3/cimbar)** (by **[sz3](https://github.com/sz3)**)
    * **CN:** 提供了核心的高密度彩色二维条码算法。
    * **EN:** Provided the core high-density color 2D barcode algorithm and implementation.
* **[cfc](https://github.com/sz3/cfc)** (by **[sz3](https://github.com/sz3)**)
    * **CN:** 提供了高效的传输协议与流控制逻辑。
    * **EN:** Contributed the efficient transport protocol and flow control logic.
* **[cfcforios](https://github.com/Superinterface/cfcforios)** (by **[Superinterface](https://github.com/Superinterface)**)
    * **CN:** 提供了 iOS 端的初始移植方案与 Swift/C++ 集成框架。
    * **EN:** Provided the foundational iOS port and Swift/C++ integration framework.

### 💡 特别鸣谢 / Special Thanks

特别感谢 **[sz3](https://github.com/sz3)** 在 **[Issue #65](https://github.com/sz3/cfc/issues/65)** 中分享的技术洞察，这些见解为本项目在 iOS 端的优化与功能完善提供了关键指导。

Special thanks to **[sz3](https://github.com/sz3)** and **[Issue #65](https://github.com/sz3/cfc/issues/65)** for the technical insights shared in Issue #65, which provided critical guidance for the refinement and optimization of this application.

# cfcforios

## ⚠️ Important: OpenCV Not Included / 重要提示：未包含 OpenCV

> [!IMPORTANT]
> To keep this repository lightweight, the **opencv2.framework** (approx. 400MB+) is **NOT** included in this repository. You **MUST** download it manually before building the project.
> 为保持仓库轻量化，本项目**不包含** **opencv2.framework**（体积约 400MB+）。在编译运行前，你**必须**手动下载并配置该框架，否则无法通过编译。

---

## 🛠 Prerequisites / 前提条件

### 1. Download OpenCV / 下载 OpenCV
- **Version / 版本**: OpenCV 2.4.x (iOS pack).
- **Download Link / 下载地址**: [OpenCV Official Releases](https://opencv.org/releases/).
- **Action / 操作**: Download the **iOS pack**, unzip it, and locate the `opencv2.framework` folder.
- **操作指南**: 下载 **iOS pack**，解压并找到 `opencv2.framework` 文件夹。

### 2. Manual Installation / 手动安装步骤
After cloning this repository, follow these steps to avoid "Framework not found" errors:
克隆本仓库后，请执行以下步骤以避免“Framework not found”编译错误：

1. **Create Folder / 创建目录**: 
   Create a folder named `Frameworks` in the project root directory.
   在项目根目录下创建一个名为 `Frameworks` 的文件夹。
2. **Copy Framework / 拷贝文件**: 
   Move your downloaded `opencv2.framework` into this `Frameworks/` folder.
   将下载好的 `opencv2.framework` 移动（或拷贝）到这个 `Frameworks/` 文件夹中。
3. **Xcode Check / Xcode 检查**:
   - Open `cfcforios.xcodeproj`.
   - Go to **Target** -> **General** -> **Frameworks, Libraries, and Embedded Content**.
   - Ensure `opencv2.framework` is listed. If it is missing (shown in red), drag and drop it there from your `Frameworks/` folder.
   - Set it to **Do Not Embed** (OpenCV 2 is typically a static library).
   - 在 Xcode 的 **General** 选项卡中确认已添加该库，并设置为 **Do Not Embed**。

---

## 🚀 Getting Started / 快速开始

1. Clone the repo: `git clone https://github.com/neverfire007/cfcforios.git`
2. Complete the **OpenCV** setup mentioned above.
3. Open the project in Xcode.
4. Build and Run on your iOS device or simulator.

---

## 📄 License
[Insert your license info here, e.g., MIT]
