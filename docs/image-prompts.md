# AutoDoor Mod — 僵尸毁灭工程风格贴图生成 Prompt 集

适用于 Stable Diffusion / Flux / Midjourney / 即梦 / 文心一格 等 AI 绘图工具。
目标：复刻《僵尸毁灭工程》(Project Zomboid) 的原版物品图标视觉语言。

---

## 0. 风格基准（Style Anchor）— 所有 Prompt 共用

PZ 物品图标的核心视觉特征（生成前先理解，Prompt 中逐条落实）：

| 特征 | 描述 |
|---|---|
| 媒介质感 | 手绘 + 轻微颗粒噪点，类似旧式游戏素材扫描件，非纯矢量 |
| 线条 | 深棕黑色粗描边，边缘略有手抖的不均匀感 |
| 色彩 | 低饱和、偏灰的实用主义配色（橄榄灰/锈棕/暗黄铜/雾白），禁鲜艳 |
| 光照 | 单一方向顶光 + 底部柔和投影（地面阴影），物体自身明暗过渡硬朗 |
| 构图 | 物品居中、正面/3/4 视角、孤立无场景、无透视背景 |
| 背景 | 纯白或极浅灰白（#f2f2f2），便于抠图 |
| 文字 | 禁止任何文字、数字、logo、水印 |
| 时代感 | 轻微磨损、锈迹、使用痕迹（末日生存物品该有的样子） |

**通用风格段（中 / EN）**——所有 Prompt 都粘贴这段：

```
2D 游戏物品图标，僵尸毁灭工程 Project Zomboid 原版美术风格，手绘质感，深棕黑色粗描边，低饱和灰调配色，轻微纸张颗粒噪点，顶部柔光与底部投影，物品居中孤立构图，纯白背景，无文字无水印，正面视角，复古末日生存游戏 UI 图标
```

```
2D game item icon in the exact art style of Project Zomboid, hand-drawn texture, thick dark brown-black outlines with slightly uneven strokes, desaturated muted grey-green palette, subtle paper grain noise, soft top light with grounding shadow beneath, centered isolated single object composition, plain white background, no text no watermark, front view, retro post-apocalyptic survival game inventory icon
```

---

## 1. 自动门遥控器（Item_RemoteDoorOpener.png）

**中文 Prompt（通用 / 即梦 / 文心一格）：**

> 2D 游戏物品图标，僵尸毁灭工程 Project Zomboid 原版美术风格，手绘质感，深棕黑色粗描边，低饱和灰调配色，轻微纸张颗粒噪点，顶部柔光与底部投影，物品居中孤立构图，纯白背景，无文字无水印，正面视角，复古末日生存游戏 UI 图标。
> 主体：一只老式电视遥控器，深灰色磨砂塑料机身，圆角矩形，顶部一条黑色小液晶屏幕，屏幕下方并排两个圆形按键（左红右蓝，塑料质感微微掉漆），中央一个大的圆形黄色按键，底部一颗绿色小指示灯，机身右侧表面有一道细划痕和浅灰色污渍，整体呈轻微使用磨损状态，比例宽厚敦实，末日手作质感

**English Prompt（SDXL / Flux）：**

> 2D game item icon in the exact art style of Project Zomboid, hand-drawn texture, thick dark brown-black outlines with slightly uneven strokes, desaturated muted color palette, subtle paper grain noise, soft top light with grounding shadow beneath, centered isolated single object, plain white background, no text no watermark, front view, retro post-apocalyptic survival game inventory icon.
> A single old-fashioned TV remote control: dark grey matte plastic body, rounded rectangle, small black LCD strip at top, two round push buttons side by side below the screen (red left, blue right, slightly chipped paint), one large round yellow button in the center, small green indicator LED at the bottom, a thin scratch and light grey grime on the right side of the body, worn utilitarian look, chunky proportions, hand-made apocalypse feel

---

## 2. 自动门钥匙（Item_AutoDoorKey.png）

**中文 Prompt：**

> 2D 游戏物品图标，僵尸毁灭工程 Project Zomboid 原版美术风格，手绘质感，深棕黑色粗描边，低饱和灰调配色，轻微纸张颗粒噪点，顶部柔光与底部投影，物品居中孤立构图，纯白背景，无文字无水印，正面视角，复古末日生存游戏 UI 图标。
> 主体：一把老式黄铜门钥匙，顶部一个圆形钥匙环（环孔清晰），环下连接钥匙柄，柄身略微氧化发暗呈暗铜绿色，齿端两三个不对称的锯齿，钥匙表面有细擦痕和轻微锈点，钥匙环上缠着一小截褪色的布条，整体磨损做旧，钥匙朝下垂直放置

**English Prompt（SDXL / Flux）：**

> 2D game item icon in the exact art style of Project Zomboid, hand-drawn texture, thick dark outlines with uneven strokes, desaturated muted palette, subtle paper grain, soft top light and grounding shadow, centered isolated object, plain white background, no text no watermark, front view, retro post-apocalyptic survival game inventory icon.
> A single old brass door key: round keyring hole at top, key shaft below, darkened oxidized brass-green patina on the shank, two or three uneven notches at the teeth, fine scratches and tiny rust spots on the surface, a small frayed strip of faded cloth tied around the ring, vertical orientation, heavily worn

---

## 3. 自动车库门（Item_AutoGarageDoor.png）

> 说明：这张既用作建造菜单图标，也可拆解成 tileset 参考（3 格卷帘门整体图）。

**中文 Prompt：**

> 2D 游戏物品图标，僵尸毁灭工程 Project Zomboid 原版美术风格，手绘质感，深棕黑色粗描边，低饱和灰调配色，轻微纸张颗粒噪点，顶部柔光与底部投影，物品居中孤立构图，纯白背景，无文字无水印，正面视角，复古末日生存游戏 UI 图标。
> 主体：一扇闭合的灰色金属卷帘车库门，宽高比约 2:1 的横向矩形门板，表面为横向排列的波浪卷帘槽（五到六条凸起横棱），门板两侧各有垂直轨道槽，中央靠下有一个横向金属门把手，门面右下角有一小片锈迹和一道刮痕，金属灰配色（比遥控器更浅的钢板灰），工业质感，正面平视

**English Prompt（SDXL / Flux）：**

> 2D game item icon in the exact art style of Project Zomboid, hand-drawn texture, thick dark outlines, desaturated muted palette, subtle paper grain, soft top light and grounding shadow, centered isolated object, plain white background, no text no watermark, front view, retro post-apocalyptic survival game inventory icon.
> A single closed grey metal roller garage door, wide horizontal rectangle panel with an aspect ratio of about 2:1, five or six raised horizontal corrugated slats across the panel, vertical track rails on both sides, one horizontal metal pull handle near the lower center, a small rust patch and a scratch at the lower right corner, light steel-grey industrial paint, flat frontal view

---

## 4. 自动栅栏门（Item_AutoFenceGate.png）

**中文 Prompt：**

> 2D 游戏物品图标，僵尸毁灭工程 Project Zomboid 原版美术风格，手绘质感，深棕黑色粗描边，低饱和灰调配色，轻微纸张颗粒噪点，顶部柔光与底部投影，物品居中孤立构图，纯白背景，无文字无水印，正面视角，复古末日生存游戏 UI 图标。
> 主体：一扇锈蚀的金属丝网栅栏门，方形金属边框，内部为菱格或方格铁丝网（网孔疏密不均），边框四角有焊接点，门中部横着一条加固扁钢，右下角铰链结构清晰，网面上挂着一两片枯叶，金属铁灰与暗锈棕配色，正面平视

**English Prompt（SDXL / Flux）：**

> 2D game item icon in the exact art style of Project Zomboid, hand-drawn texture, thick dark outlines, desaturated muted palette, subtle paper grain, soft top light and grounding shadow, centered isolated object, plain white background, no text no watermark, front view, retro post-apocalyptic survival game inventory icon.
> A single rusted metal wire-mesh fence gate, square metal frame, diamond or square wire mesh inside with unevenly spaced cells, visible weld spots at the four corners, one horizontal reinforcing flat bar across the middle, clear hinge structure at the lower right corner, one or two dried leaves caught in the mesh, iron grey with dark rust-brown accents, flat frontal view

---

## 5. Mod 海报 poster（poster.png，512×256 横版）

**中文 Prompt：**

> 僵尸毁灭工程 Project Zomboid 风格横版封面图，手绘厚涂与粗描边，低饱和灰绿末日配色，纸张颗粒噪点。
> 画面：正中央一只放在粗糙木桌上的旧遥控器，微微俯视；遥控器背后远景是一扇敞开一半的灰色金属卷帘车库门，门缝透出昏黄灯光；右侧延伸一段锈蚀金属丝网栅栏和栅栏门；窗外远处是末日后的灰暗小镇轮廓。构图横向均衡，色调统一偏暗，气氛压抑写实，顶部留出空白区域，无文字无logo

**English Prompt：**

> Project Zomboid style wide banner illustration, hand-painted with thick outlines, desaturated grey-green apocalypse palette, paper grain texture.
> Center: an old remote control lying on a rough wooden table, slight top-down angle; behind it in the mid-ground a grey metal roller garage door half-open, dim warm light spilling through the gap; on the right a stretch of rusted wire-mesh fence with a gate; in the far distance the grey silhouette of a post-apocalyptic small town. Balanced horizontal composition, unified dark desaturated tones, oppressive realistic mood, empty space at the top for title, no text no logo

---

## 6. 负面提示词（Negative Prompt）— 全部通用

```
英文：
text, watermark, signature, logo, letters, numbers, border, frame, multiple objects, duplicate, 3d render, photo, realistic photo, cgi, shiny plastic gloss, neon, vibrant saturated colors, cartoon anime, chibi, glossy, outline art style mismatch, background scene, perspective background, hands, person, corpse, blood gore, extra fingers, deformed, low quality, blurry, jpeg artifacts
```

```
中文（针对国产工具）：
文字，水印，签名，logo，字母，数字，边框，相框，多个物体，重复，3D渲染，照片，写实照片，CG，塑料反光高光，霓虹，鲜艳高饱和，动漫卡通，Q版，描边风格不一致，场景背景，透视背景，手，人物，尸体，血腥，手指畸形，低质量，模糊，压缩噪点
```

---

## 7. 各平台参数建议

| 平台 | 参数 |
|---|---|
| **Midjourney** | 物品图标版：`--ar 1:1 --style raw --stylize 120 --v 6`；poster 版：`--ar 2:1 --style raw --stylize 200`；可加 `--no text, watermark` |
| **SDXL / Flux** | 建议 1024×1024（poster 1024×512）；CFG 5-7；采样 30-40 步；提示词用英文 positive + negative 分栏 |
| **即梦 / 文心一格** | 用中文 Prompt；生成后选"高清重绘"或"智能扩图"修边；分辨率优先 1024×1024 |
| **通用技巧** | ① 多抽几张选线稿最稳的 ② 用"局部重绘"修按钮/锯齿等细节 ③ 导出后缩小到目标尺寸 ④ 若背景不是纯白，用去背景工具（如 remove.bg）抠成透明 PNG |

---

## 8. 产出规格与入库路径

| 文件 | 用途 | 目标尺寸 | 入库路径 |
|---|---|---|---|
| 遥控器图 | 物品图标 | 128×128（透明底 PNG，可出 256×256 2x） | `media/textures/Item_RemoteDoorOpener.png` |
| 钥匙图 | 物品图标 | 128×128 | `media/textures/Item_AutoDoorKey.png` |
| 车库门图 | 建造菜单图标 | 128×128 | `media/textures/Item_AutoGarageDoor.png` |
| 栅栏门图 | 建造菜单图标 | 128×128 | `media/textures/Item_AutoFenceGate.png` |
| 海报图 | mod.info 封面 | 512×256（2:1） | `poster.png` |

处理流程：AI 出图（1024×1024）→ 去背景/确认纯白 → 缩小到目标尺寸 → 覆盖同名文件 → 重新部署到
`C:\Users\Origin\Zomboid\mods\AutoDoorRemote\`（图标直接替换 `media/textures/` 下的同名 PNG 即可，无需改代码）。
