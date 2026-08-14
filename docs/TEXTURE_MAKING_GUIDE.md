# AutoDoor Mod 贴图制作完整指南

##  概述

本指南帮助你为 AutoDoor Mod 生成符合《僵尸毁灭工程》(Project Zomboid) 原版风格的贴图。所有贴图都需要遵循PZ的手绘质感、低饱和配色和像素级精确的尺寸要求。

---

## 🎯 需要制作的贴图

| # | 文件名 | 尺寸 | 用途 |
|---|--------|------|------|
| 1 | `Item_RemoteDoorOpener.png` | 128×128 | 遥控器物品图标 |
| 2 | `Item_AutoDoorKey.png` | 128×128 | 钥匙物品图标 |
| 3 | `Item_AutoDoorMagazine.png` | 128×128 | 杂志/说明书图标 |
| 4 | `Item_AutoGarageDoor.png` | 128×128 | 车库门建造图标 |
| 5 | `Item_AutoFenceGate.png` | 128×128 | 栅栏门建造图标 |
| 6 | `poster.png` | 512×256 | Mod封面海报 |

---

## 🛠️ 方法一：使用AI绘图工具（推荐）

### 方案A：使用SD WebUI批量生成（全自动）

**前置条件：**
- 已安装 Stable Diffusion WebUI (AUTOMATIC1111 或 ComfyUI)
- 已下载 SDXL 或 Flux 模型
- GPU显存 ≥ 8GB

**步骤：**

1. **启动SD WebUI并开启API**
   ```bash
   # AUTOMATIC1111
   python webui.py --api
   
   # 或指定端口
   python webui.py --api --port 7860
   ```

2. **安装Python依赖**
   ```bash
   pip install requests Pillow
   ```

3. **运行批量生成脚本**
   ```bash
   cd D:\Code\autodoor
   python tools/generate_textures_sdwebui.py
   ```
   
   生成的图像会保存到 `raw_outputs/` 目录，每个贴图一个子文件夹。

4. **运行后处理脚本**
   ```bash
   python tools/postprocess_textures.py --input-dir ./raw_outputs --output-dir ./42/media/textures
   ```

5. **验证结果**
   检查 `42/media/textures/` 目录下是否所有PNG都已正确生成。

---

### 方案B：手动使用AI工具（即梦/文心一格/Midjourney）

如果你没有本地GPU或不方便部署SD WebUI，可以使用在线AI绘图工具。

**步骤：**

1. **选择平台**
   - **即梦4.0** (jimeng.jianying.com) - 免费额度多，中文友好
   - **文心一格** (yige.baidu.com) - 国内访问快
   - **Midjourney** - 质量最好但需付费订阅
   - **Flux via Replicate/Fal.ai** - 云端API，按量付费

2. **复制提示词**
   打开 `docs/texture-generation-guide.md`，找到对应贴图的Prompt部分，复制Positive Prompt和Negative Prompt。

3. **设置参数**
   - 分辨率：1024×1024（物品图标）或 1024×512（海报）
   - 风格：选择"写实"或"手绘"模式
   - 生成数量：每次4-8张，挑选最佳

4. **下载原图**
   选择最符合PZ风格的图像下载（优先选线稿清晰、色彩低饱和的）。

5. **后处理**
   将下载的图像放到 `raw_outputs/` 目录，然后运行：
   ```bash
   python tools/postprocess_textures.py --input-dir ./raw_outputs --output-dir ./42/media/textures
   ```

---

### 方案C：使用ComfyUI工作流

如果你熟悉ComfyUI，可以创建工作流实现更精细的控制。

**推荐节点配置：**
- Checkpoint: SDXL Base 或 Flux Dev
- CLIP Text Encode (Positive): 粘贴风格锚点 + 物品描述
- CLIP Text Encode (Negative): 粘贴负面提示词
- KSampler: DPM++ 2M Karras, 30-40 steps, CFG 5-7
- VAE Decode → Save Image
- 可选添加 ControlNet Lineart 预处理器稳定线稿

---

## 🎨 PZ风格关键要素

无论使用哪种方法，确保生成的贴图符合以下特征：

| 特征 | 要求 | 检查方法 |
|------|------|----------|
| **描边** | 深棕黑色粗描边，边缘略有手抖感 | 放大查看线条是否均匀但有轻微不规则 |
| **色彩** | 低饱和灰调（橄榄灰/锈棕/暗黄铜） | 用取色器检查，避免RGB差值>100的鲜艳色 |
| **背景** | 纯白 #FFFFFF 或极浅灰 #F2F2F2 | 用魔棒工具测试是否能一键选中背景 |
| **光照** | 顶部柔光 + 底部投影 | 物体上方略亮，下方有柔和阴影 |
| **质感** | 纸张颗粒噪点，非纯矢量 | 放大看是否有细微纹理而非平滑渐变 |
| **构图** | 物品居中，无透视背景 | 确认没有地面、桌面等环境元素 |
| **文字** | 绝对无文字/数字/logo | 仔细检查每个角落 |
| **磨损** | 轻微锈迹/划痕/使用痕迹 | 末日生存物品应有的岁月感 |

---

##  后处理脚本详解

`tools/postprocess_textures.py` 自动完成以下操作：

1. **去背景** - 将接近白色的区域转为透明
2. **裁剪** - 去除多余空白，保留4px边距
3. **缩放** - 强制缩放到目标尺寸（128×128或512×256）
4. **验证** - 检查Alpha通道、饱和度、完整性
5. **保存** - 输出优化后的PNG到Mod目录

**使用示例：**
```bash
# 批量处理所有贴图
python tools/postprocess_textures.py --input-dir ./raw_outputs --output-dir ./42/media/textures

# 只处理单个贴图
python tools/postprocess_textures.py --single Item_RemoteDoorOpener --input-dir ./raw_outputs

# 自定义输出目录
python tools/postprocess_textures.py --input-dir ./my_images --output-dir ./42/media/textures
```

---

## ✅ 质量检查清单

生成每张贴图后，逐一检查：

- [ ] 尺寸严格符合要求（128×128或512×256）
- [ ] PNG有Alpha通道（透明背景）
- [ ] 无白色实心背景残留
- [ ] 描边粗细适中（在128px下约2-3px）
- [ ] 色彩饱和度低（无鲜艳纯色）
- [ ] 无文字、水印、logo
- [ ] 物品主体清晰可辨
- [ ] 有轻微磨损/锈迹细节
- [ ] 在游戏内实际加载测试显示正常

---

## 📁 文件结构

```
D:\Code\autodoor\
├── docs\
│   ├── image-prompts.md              # 原始提示词文档
│   ── texture-generation-guide.md   # 详细提示词+参数指南
├── tools\
│   ├── generate_textures_sdwebui.py  # SD WebUI批量生成脚本
│   ── postprocess_textures.py       # 后处理脚本
├── raw_outputs\                      # AI生成原图（临时）
│   ├── Item_RemoteDoorOpener\
│   ├── Item_AutoDoorKey\
│   └── ...
── 42\
    └── media\
        └── textures\                 # ← 最终贴图存放位置
            ├── Item_RemoteDoorOpener.png
            ├── Item_AutoDoorKey.png
            ├── Item_AutoDoorMagazine.png
            ├── Item_AutoGarageDoor.png
            ├── Item_AutoFenceGate.png
            └── poster.png
```

---

## ️ 常见问题

**Q: 生成的图像背景不是纯白怎么办？**
A: 后处理脚本会自动处理。如果效果不佳，手动用Photoshop/GIMP的魔棒工具删除背景。

**Q: 色彩太鲜艳不像PZ风格？**
A: 在Positive Prompt中强调 "desaturated muted palette"，或在Negative Prompt中加入 "vibrant saturated colors"。也可后期用图像处理软件降低饱和度。

**Q: 描边太细或太粗？**
A: 调整CFG Scale（5-7之间），或在Prompt中明确指定 "thick dark brown-black outlines"。ControlNet Lineart有助于稳定线稿。

**Q: 游戏内显示模糊？**
A: 确保最终PNG是128×128精确尺寸，不要用其他尺寸缩放。检查PZ游戏设置中的纹理质量选项。

**Q: SD WebUI生成速度太慢？**
A: 减少batch_size，或使用FP16精度，或切换到更小的模型（如SD 1.5 + LoRA）。

---

## 🚀 快速开始（3步搞定）

如果你已有SD WebUI环境：

```bash
# 1. 启动WebUI（新终端窗口）
cd /path/to/stable-diffusion-webui
python webui.py --api

# 2. 批量生成（此项目目录）
cd D:\Code\autodoor
pip install requests Pillow
python tools/generate_textures_sdwebui.py

# 3. 后处理
python tools/postprocess_textures.py
```

完成后检查 `42/media/textures/` 目录，所有贴图应已就位！

---

## 📞 技术支持

- 详细提示词参考：`docs/texture-generation-guide.md`
- 原始设计文档：`docs/image-prompts.md`
- PZ Modding Wiki: https://pzwiki.net/
- Project Zomboid Discord: https://discord.gg/projectzomboid

---

*最后更新: 2024 | 适用于 Project Zomboid Build 42+*
