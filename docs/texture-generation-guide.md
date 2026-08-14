# AutoDoor Mod 贴图生成完整指南

## 📋 贴图清单与规格

| # | 文件名 | 尺寸 | 用途 | 状态 |
|---|--------|------|------|------|
| 1 | Item_RemoteDoorOpener.png | 128×128 | 遥控器物品图标 | 需重制 |
| 2 | Item_AutoDoorKey.png | 128×128 | 钥匙物品图标 | 需重制 |
| 3 | Item_AutoDoorMagazine.png | 128×128 | 杂志/说明书图标 | 需重制 |
| 4 | Item_AutoGarageDoor.png | 128×128 | 车库门建造图标 | 需重制 |
| 5 | Item_AutoFenceGate.png | 128×128 | 栅栏门建造图标 | 需重制 |
| 6 | poster.png | 512×256 | Mod封面海报 | 需重制 |

---

## 🎨 通用风格锚点（所有Prompt必加）

### 中文风格段
```
2D游戏物品图标，僵尸毁灭工程Project Zomboid原版美术风格，手绘质感，深棕黑色粗描边且边缘略有手抖不均匀感，低饱和灰调配色（橄榄灰/锈棕/暗黄铜/雾白），轻微纸张颗粒噪点模拟旧式扫描件，单一方向顶光+底部柔和投影，物品居中孤立构图无透视背景，纯白背景#f2f2f2便于抠图，禁止任何文字数字logo水印，正面或3/4视角，复古末日生存游戏UI图标，轻微磨损锈迹使用痕迹
```

### English Style Anchor
```
2D game item icon in the exact art style of Project Zomboid, hand-drawn texture with subtle paper grain noise resembling vintage scanned game assets, thick dark brown-black outlines with slightly uneven hand-wobbly strokes, desaturated muted utilitarian palette (olive grey/rust brown/dark brass/fog white), single-direction top light with soft grounding shadow beneath, centered isolated composition without perspective background, pure white background #f2f2f2 for easy cutout, absolutely no text numbers logo watermark, front or 3/4 view, retro post-apocalyptic survival game inventory icon, slight wear rust and usage marks
```

### Negative Prompt（负面提示词）
```
text, watermark, signature, logo, letters, numbers, border, frame, multiple objects, duplicate items, 3d render, photo, realistic photograph, cgi, shiny plastic gloss, neon lights, vibrant saturated colors, cartoon anime style, chibi, glossy finish, outline style mismatch, background scene, perspective background, hands, person, corpse, blood gore, extra fingers, deformed anatomy, low quality, blurry, jpeg artifacts, digital vector art, flat color fill, cel shading
```

---

## 🔧 各贴图专用Prompt

### 1. 遥控器（Item_RemoteDoorOpener.png）

**English Positive:**
```
2D game item icon in the exact art style of Project Zomboid, hand-drawn texture with subtle paper grain noise, thick dark brown-black outlines with slightly uneven strokes, desaturated muted utilitarian palette, soft top light with grounding shadow, centered isolated object, plain white background, no text no watermark, front view, retro post-apocalyptic survival game inventory icon.

A single old-fashioned TV remote control: dark grey matte plastic body with rounded rectangle shape, small black LCD strip at the top, two round push buttons side by side below the screen (red on left, blue on right, with slightly chipped paint showing wear), one large round yellow button in the center, small green indicator LED at the bottom, a thin scratch and light grey grime mark on the right side of the body, worn utilitarian look with chunky proportions, hand-made apocalypse feel, slight oxidation on edges
```

**中文Positive:**
```
2D游戏物品图标，僵尸毁灭工程Project Zomboid原版美术风格，手绘质感，深棕黑色粗描边，低饱和灰调配色，轻微纸张颗粒噪点，顶部柔光与底部投影，物品居中孤立构图，纯白背景，无文字无水印，正面视角，复古末日生存游戏UI图标。

主体：一只老式电视遥控器，深灰色磨砂塑料机身呈圆角矩形，顶部一条黑色小液晶屏幕，屏幕下方并排两个圆形按键（左红右蓝，塑料质感微微掉漆露出底色），中央一个大的圆形黄色按键，底部一颗绿色小指示灯，机身右侧表面有一道细划痕和浅灰色污渍，整体呈轻微使用磨损状态，比例宽厚敦实，末日手作质感，边缘略有氧化
```

**推荐参数：**
- SDXL/Flux: 1024×1024, CFG 6, Steps 35, Sampler DPM++ 2M Karras
- Midjourney: `--ar 1:1 --style raw --stylize 120 --v 6.0`
- 即梦/文心一格: 高清模式，智能扩图修边

---

### 2. 钥匙（Item_AutoDoorKey.png）

**English Positive:**
```
2D game item icon in the exact art style of Project Zomboid, hand-drawn texture with subtle paper grain, thick dark brown-black outlines with uneven hand-drawn strokes, desaturated muted palette, soft top light and grounding shadow beneath, centered isolated single object, plain white background, no text no watermark, front view, retro post-apocalyptic survival game inventory icon.

A single old brass door key hanging vertically: round keyring hole at the top bow, key shaft below with darkened oxidized brass-green patina, two or three uneven notches at the teeth end, fine scratches and tiny rust spots scattered on the surface, a small frayed strip of faded cloth tied around the ring, heavily worn and aged appearance, vertical orientation pointing downward, utilitarian pre-war craftsmanship
```

**中文Positive:**
```
2D游戏物品图标，僵尸毁灭工程Project Zomboid原版美术风格，手绘质感，深棕黑色粗描边且笔触不均匀，低饱和灰调配色，轻微纸张颗粒噪点，顶部柔光与底部投影，物品居中孤立构图，纯白背景，无文字无水印，正面视角，复古末日生存游戏UI图标。

主体：一把老式黄铜门钥匙垂直悬挂，顶部圆形钥匙环孔清晰，环下连接钥匙柄，柄身略微氧化发暗呈暗铜绿色包浆，齿端两三个不对称的锯齿，钥匙表面散布细擦痕和轻微锈点，钥匙环上缠着一小截褪色磨损的布条，整体重度磨损做旧，钥匙朝下垂直放置，战前实用主义工艺感
```

**推荐参数：**
- SDXL/Flux: 1024×1024, CFG 5.5, Steps 30
- Midjourney: `--ar 1:1 --style raw --stylize 100 --v 6.0`

---

### 3. 杂志/说明书（Item_AutoDoorMagazine.png）

**English Positive:**
```
2D game item icon in the exact art style of Project Zomboid, hand-drawn texture with paper grain noise, thick dark brown-black outlines with slightly wobbly strokes, desaturated muted color palette, soft top light with grounding shadow, centered isolated object, plain white background, no text no watermark, front view, retro post-apocalyptic survival game inventory icon.

A single folded DIY electronics magazine or instruction booklet: off-white aged paper cover with yellowed edges, visible crease lines from being folded, a simple line-drawing illustration of a circuit board or radio receiver on the cover in faded ink, dog-eared corner at top right, slight coffee stain ring near bottom left, worn spine with frayed edges, utilitarian pre-war hobbyist publication aesthetic, flat frontal view
```

**中文Positive:**
```
2D游戏物品图标，僵尸毁灭工程Project Zomboid原版美术风格，手绘质感带纸张颗粒噪点，深棕黑色粗描边且笔触略抖动，低饱和灰调配色，顶部柔光与底部投影，物品居中孤立构图，纯白背景，无文字无水印，正面视角，复古末日生存游戏UI图标。

主体：一本折叠的DIY电子学杂志或说明书手册，泛黄老旧纸张封面边缘发黄，可见折叠产生的折痕线，封面上用褪色墨水绘制着简单的电路板或收音机接收器线条图，右上角有卷起的狗耳朵折角，左下角靠近底部有轻微的咖啡渍圆环，书脊磨损边缘毛糙，战前业余爱好者出版物的实用美学，正面平视
```

**推荐参数：**
- SDXL/Flux: 1024×1024, CFG 6, Steps 35
- Midjourney: `--ar 1:1 --style raw --stylize 130 --v 6.0`

---

### 4. 车库门（Item_AutoGarageDoor.png）

**English Positive:**
```
2D game item icon in the exact art style of Project Zomboid, hand-drawn texture with subtle paper grain, thick dark brown-black outlines with uneven strokes, desaturated muted industrial palette, soft top light with grounding shadow beneath, centered isolated object, plain white background, no text no watermark, front view, retro post-apocalyptic survival game inventory icon.

A single closed grey metal roller garage door panel: wide horizontal rectangle with aspect ratio approximately 2:1, five to six raised horizontal corrugated slats across the panel surface, vertical track rails on both left and right sides, one horizontal metal pull handle positioned near the lower center, a small rust patch and a diagonal scratch at the lower right corner, light steel-grey industrial paint with weathered texture, flat frontal orthographic view, heavy utilitarian construction
```

**中文Positive:**
```
2D游戏物品图标，僵尸毁灭工程Project Zomboid原版美术风格，手绘质感带轻微纸张颗粒，深棕黑色粗描边且笔触不均匀，低饱和工业灰调配色，顶部柔光与底部投影，物品居中孤立构图，纯白背景，无文字无水印，正面视角，复古末日生存游戏UI图标。

主体：一扇闭合的灰色金属卷帘车库门面板，宽高比约2:1的横向矩形，门板表面有五到六条凸起的横向波浪卷帘槽，左右两侧各有垂直轨道槽，中央靠下位置有一个横向金属拉手，右下角有一小片锈迹和一道斜向刮痕，浅钢板灰色工业漆面带有风化纹理，正面正交视图，厚重的实用主义构造
```

**推荐参数：**
- SDXL/Flux: 1024×1024, CFG 5.5, Steps 30
- Midjourney: `--ar 1:1 --style raw --stylize 110 --v 6.0`

---

### 5. 栅栏门（Item_AutoFenceGate.png）

**English Positive:**
```
2D game item icon in the exact art style of Project Zomboid, hand-drawn texture with paper grain noise, thick dark brown-black outlines with slightly uneven hand-drawn strokes, desaturated muted palette, soft top light and grounding shadow, centered isolated single object, plain white background, no text no watermark, front view, retro post-apocalyptic survival game inventory icon.

A single rusted metal wire-mesh fence gate: square metal frame with visible weld spots at the four corners, diamond-pattern wire mesh inside with unevenly spaced cells, one horizontal reinforcing flat bar running across the middle, clear hinge structure at the lower right corner with rusted bolts, one or two dried brown leaves caught in the mesh, iron grey frame with dark rust-brown accents and corrosion patches, flat frontal view, neglected suburban backyard aesthetic
```

**中文Positive:**
```
2D游戏物品图标，僵尸毁灭工程Project Zomboid原版美术风格，手绘质感带纸张颗粒噪点，深棕黑色粗描边且笔触略不均匀，低饱和灰调配色，顶部柔光与底部投影，物品居中孤立构图，纯白背景，无文字无水印，正面视角，复古末日生存游戏UI图标。

主体：一扇锈蚀的金属丝网栅栏门，方形金属边框四角有可见焊接点，内部为菱形铁丝网且网孔疏密不均，中部横着一条加固扁钢，右下角铰链结构清晰可见带锈螺栓，网面上挂着一两片枯褐色叶子，铁灰色框架配暗锈棕色锈迹和腐蚀斑块，正面平视，被遗弃的郊区后院美学
```

**推荐参数：**
- SDXL/Flux: 1024×1024, CFG 6, Steps 35
- Midjourney: `--ar 1:1 --style raw --stylize 120 --v 6.0`

---

### 6. 海报（poster.png）

**English Positive:**
```
Project Zomboid style wide banner illustration, hand-painted with thick dark outlines and paper grain texture, desaturated grey-green apocalypse palette, oppressive realistic mood.

Horizontal composition: in the foreground center, an old remote control lying on a rough wooden table surface with slight top-down angle; behind it in the mid-ground, a grey metal roller garage door half-open with dim warm yellow light spilling through the gap; extending to the right side, a stretch of rusted wire-mesh fence with a gate; in the far distance through the opening, the grey silhouette of a post-apocalyptic small town under overcast sky. Balanced horizontal layout, unified dark desaturated tones, empty space at the top third for title placement, absolutely no text no logo no watermark, cinematic but grounded in PZ's hand-drawn aesthetic
```

**中文Positive:**
```
僵尸毁灭工程Project Zomboid风格横版封面插画，手绘厚涂带深棕黑色粗描边和纸张颗粒纹理，低饱和灰绿末日配色，压抑写实气氛。

横向构图：前景中央一只老式遥控器放在粗糙木桌表面，微微俯视角度；中景后方一扇灰色金属卷帘车库门半开，门缝透出昏黄暖光；右侧延伸一段锈蚀金属丝网栅栏和栅栏门；远处透过门洞可见阴天下末日小镇的灰暗轮廓。横向均衡布局，统一暗调低饱和色调，顶部三分之一留白供标题放置，绝对无文字无logo无水印，电影感但扎根于僵毁的手绘美学
```

**推荐参数：**
- SDXL/Flux: 1024×512, CFG 7, Steps 40
- Midjourney: `--ar 2:1 --style raw --stylize 200 --v 6.0`

---

## 🛠️ 后处理流程

### 步骤1：去背景（如AI未输出纯白底）
使用以下工具之一：
- **remove.bg** - 在线自动抠图
- **Photoshop/GIMP** - 魔棒工具选择白色背景删除
- **Python脚本**（见下方自动化脚本）

### 步骤2：缩放至目标尺寸
```bash
# 使用ImageMagick
convert input.png -resize 128x128! Item_RemoteDoorOpener.png
convert input.png -resize 512x256! poster.png
```

### 步骤3：验证透明度
确保PNG有Alpha通道（透明背景），可用以下命令检查：
```bash
identify -verbose output.png | grep "Type"
# 应显示 "TrueColorAlpha"
```

### 步骤4：部署到Mod目录
将生成的PNG文件复制到：
```
D:\Code\autodoor\42\media\textures\
```
以及Steam创意工坊上传目录（如有）：
```
C:\Users\Origin\Zomboid\mods\AutoDoorRemote\media\textures\
```

---

##  平台对比与建议

| 平台 | 优点 | 缺点 | 推荐指数 |
|------|------|------|----------|
| **Flux Dev** | 对手绘风格理解最好，细节控制精准 | 需要本地GPU或云端API | ⭐⭐⭐⭐⭐ |
| **SDXL + ControlNet** | 可精确控制构图，批量生成快 | 需要训练LoRA或精细调参 | ⭐⭐⭐⭐ |
| **Midjourney v6** | 开箱即用，风格一致性好 | 付费订阅，无法本地部署 | ⭐⭐⭐⭐ |
| **即梦4.0** | 中文Prompt友好，免费额度多 | 风格偏现代，需多次抽卡 | ⭐⭐⭐ |
| **文心一格** | 国内访问快，中文理解好 | 手绘质感稍弱 | ⭐⭐⭐ |

**最佳实践建议：**
1. 先用Flux或SDXL生成10-20张候选
2. 选出线稿最稳、风格最接近PZ原版的3-5张
3. 用局部重绘修复按钮/锯齿/锈迹等细节
4. 导出1024×1024原图 → 去背景 → 缩小到128×128
5. 在游戏内实际测试显示效果

---

## ⚠️ 注意事项

1. **尺寸一致性**：所有物品图标必须严格128×128，海报512×256
2. **色彩校准**：生成后用取色器检查，确保没有RGB(255,0,0)等纯鲜艳色
3. **描边粗细**：PZ原版描边约2-3px（在128px尺寸下），过细则像矢量图，过粗则卡通化
4. **透明背景**：最终PNG必须有Alpha通道，不能是白色实心背景
5. **命名规范**：严格保持`Item_*.png`格式，大小写敏感
6. **测试验证**：每张贴图生成后务必在游戏内加载Mod查看实际效果

---

## 📁 文件结构参考

```
D:\Code\autodoor\
├── 42\
│   ├── media\
│   │   ├── textures\
│   │   │   ├── Item_RemoteDoorOpener.png  ← 替换此文件
│   │   │   ├── Item_AutoDoorKey.png       ← 替换此文件
│   │   │   ├── Item_AutoDoorMagazine.png  ← 替换此文件
│   │   │   ├── Item_AutoGarageDoor.png    ← 替换此文件
│   │   │   └── Item_AutoFenceGate.png     ← 替换此文件
│   │   └── scripts\
│   └── poster.png                         ← 替换此文件
── docs\
    ├── image-prompts.md                   ← 原始提示词文档
    └── texture-generation-guide.md        ← 本文件
```

---

*生成日期：2024 | 适用于Project Zomboid Build 42+*
