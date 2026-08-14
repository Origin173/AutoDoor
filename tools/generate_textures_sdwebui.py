#!/usr/bin/env python3
"""
AutoDoor Mod 贴图批量生成脚本（SD WebUI API）
依赖: requests, Pillow
用法: 
  1. 启动SD WebUI并开启API: webui.py --api
  2. 运行此脚本: python generate_textures_sdwebui.py
  
前置条件:
  - SD WebUI运行在 http://127.0.0.1:7860
  - 已加载SDXL或Flux模型
  - 推荐启用ControlNet Lineart预处理器以获得更稳定的线稿
"""

import json
import time
import base64
from pathlib import Path
from io import BytesIO

try:
    import requests
    from PIL import Image
except ImportError:
    print("错误: 需要安装依赖库")
    print("运行: pip install requests Pillow")
    exit(1)


# SD WebUI API地址
SD_WEBUI_URL = "http://127.0.0.1:7860"
API_TXT2IMG = f"{SD_WEBUI_URL}/sdapi/v1/txt2img"
API_OPTIONS = f"{SD_WEBUI_URL}/sdapi/v1/options"
API_INTERROGATE = f"{SD_WEBUI_URL}/sdapi/v1/interrogate"

# 输出目录
OUTPUT_DIR = Path("./raw_outputs")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# 通用风格提示词
STYLE_POSITIVE = """2D game item icon in the exact art style of Project Zomboid, hand-drawn texture with subtle paper grain noise resembling vintage scanned game assets, thick dark brown-black outlines with slightly uneven hand-wobbly strokes, desaturated muted utilitarian palette (olive grey/rust brown/dark brass/fog white), single-direction top light with soft grounding shadow beneath, centered isolated composition without perspective background, pure white background #f2f2f2 for easy cutout, absolutely no text numbers logo watermark, front or 3/4 view, retro post-apocalyptic survival game inventory icon, slight wear rust and usage marks"""

STYLE_NEGATIVE = """text, watermark, signature, logo, letters, numbers, border, frame, multiple objects, duplicate items, 3d render, photo, realistic photograph, cgi, shiny plastic gloss, neon lights, vibrant saturated colors, cartoon anime style, chibi, glossy finish, outline style mismatch, background scene, perspective background, hands, person, corpse, blood gore, extra fingers, deformed anatomy, low quality, blurry, jpeg artifacts, digital vector art, flat color fill, cel shading"""

# 各贴图专用描述
TEXTURE_PROMPTS = {
    "Item_RemoteDoorOpener": {
        "description": "A single old-fashioned TV remote control: dark grey matte plastic body with rounded rectangle shape, small black LCD strip at the top, two round push buttons side by side below the screen (red on left, blue on right, with slightly chipped paint showing wear), one large round yellow button in the center, small green indicator LED at the bottom, a thin scratch and light grey grime mark on the right side of the body, worn utilitarian look with chunky proportions, hand-made apocalypse feel, slight oxidation on edges",
        "size": (1024, 1024),
        "cfg_scale": 6,
        "steps": 35,
        "samples": 4,
    },
    "Item_AutoDoorKey": {
        "description": "A single old brass door key hanging vertically: round keyring hole at the top bow, key shaft below with darkened oxidized brass-green patina, two or three uneven notches at the teeth end, fine scratches and tiny rust spots scattered on the surface, a small frayed strip of faded cloth tied around the ring, heavily worn and aged appearance, vertical orientation pointing downward, utilitarian pre-war craftsmanship",
        "size": (1024, 1024),
        "cfg_scale": 5.5,
        "steps": 30,
        "samples": 4,
    },
    "Item_AutoDoorMagazine": {
        "description": "A single folded DIY electronics magazine or instruction booklet: off-white aged paper cover with yellowed edges, visible crease lines from being folded, a simple line-drawing illustration of a circuit board or radio receiver on the cover in faded ink, dog-eared corner at top right, slight coffee stain ring near bottom left, worn spine with frayed edges, utilitarian pre-war hobbyist publication aesthetic, flat frontal view",
        "size": (1024, 1024),
        "cfg_scale": 6,
        "steps": 35,
        "samples": 4,
    },
    "Item_AutoGarageDoor": {
        "description": "A single closed grey metal roller garage door panel: wide horizontal rectangle with aspect ratio approximately 2:1, five to six raised horizontal corrugated slats across the panel surface, vertical track rails on both left and right sides, one horizontal metal pull handle positioned near the lower center, a small rust patch and a diagonal scratch at the lower right corner, light steel-grey industrial paint with weathered texture, flat frontal orthographic view, heavy utilitarian construction",
        "size": (1024, 1024),
        "cfg_scale": 5.5,
        "steps": 30,
        "samples": 4,
    },
    "Item_AutoFenceGate": {
        "description": "A single rusted metal wire-mesh fence gate: square metal frame with visible weld spots at the four corners, diamond-pattern wire mesh inside with unevenly spaced cells, one horizontal reinforcing flat bar running across the middle, clear hinge structure at the lower right corner with rusted bolts, one or two dried brown leaves caught in the mesh, iron grey frame with dark rust-brown accents and corrosion patches, flat frontal view, neglected suburban backyard aesthetic",
        "size": (1024, 1024),
        "cfg_scale": 6,
        "steps": 35,
        "samples": 4,
    },
    "poster": {
        "description": "Horizontal composition: in the foreground center, an old remote control lying on a rough wooden table surface with slight top-down angle; behind it in the mid-ground, a grey metal roller garage door half-open with dim warm yellow light spilling through the gap; extending to the right side, a stretch of rusted wire-mesh fence with a gate; in the far distance through the opening, the grey silhouette of a post-apocalyptic small town under overcast sky. Balanced horizontal layout, unified dark desaturated tones, empty space at the top third for title placement, absolutely no text no logo no watermark, cinematic but grounded in PZ's hand-drawn aesthetic",
        "size": (1024, 512),
        "cfg_scale": 7,
        "steps": 40,
        "samples": 2,
    },
}


def check_api_connection():
    """检查SD WebUI API是否可用"""
    try:
        response = requests.get(f"{SD_WEBUI_URL}/sdapi/v1/options", timeout=5)
        if response.status_code == 200:
            print(f"✓ SD WebUI API连接成功: {SD_WEBUI_URL}")
            return True
        else:
            print(f"✗ API返回异常状态码: {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        print(f"✗ 无法连接到SD WebUI: {SD_WEBUI_URL}")
        print("请确保SD WebUI正在运行并启用了--api参数")
        return False
    except Exception as e:
        print(f"✗ 连接失败: {e}")
        return False


def get_current_model():
    """获取当前加载的模型信息"""
    try:
        response = requests.get(f"{SD_WEBUI_URL}/sdapi/v1/options")
        options = response.json()
        model = options.get("sd_model_checkpoint", "Unknown")
        print(f"当前模型: {model}")
        return model
    except Exception as e:
        print(f"获取模型信息失败: {e}")
        return None


def generate_texture(name, config):
    """生成单张贴图"""
    print(f"\n{'='*60}")
    print(f"生成: {name}")
    print(f"{'='*60}")
    
    positive_prompt = f"{STYLE_POSITIVE}, {config['description']}"
    negative_prompt = STYLE_NEGATIVE
    
    payload = {
        "prompt": positive_prompt,
        "negative_prompt": negative_prompt,
        "steps": config["steps"],
        "cfg_scale": config["cfg_scale"],
        "width": config["size"][0],
        "height": config["size"][1],
        "batch_size": config["samples"],
        "sampler_name": "DPM++ 2M Karras",
        "restore_faces": False,
        "tiling": False,
        "do_not_save_samples": True,  # 不保存到WebUI目录
        "do_not_save_grid": True,
    }
    
    print(f"Prompt长度: {len(positive_prompt)} 字符")
    print(f"尺寸: {config['size']}")
    print(f"CFG Scale: {config['cfg_scale']}")
    print(f"Steps: {config['steps']}")
    print(f"Batch Size: {config['samples']}")
    print("\n开始生成...")
    
    start_time = time.time()
    
    try:
        response = requests.post(API_TXT2IMG, json=payload, timeout=600)
        
        if response.status_code != 200:
            print(f"✗ API请求失败: {response.status_code}")
            print(f"响应: {response.text[:500]}")
            return False
        
        result = response.json()
        
        # 检查是否有错误
        if "info" in result:
            info = json.loads(result["info"]) if isinstance(result["info"], str) else result["info"]
            if "error" in info:
                print(f"✗ 生成错误: {info['error']}")
                return False
        
        # 保存生成的图像
        images = result.get("images", [])
        if not images:
            print("✗ 未收到生成的图像")
            return False
        
        output_dir = OUTPUT_DIR / name
        output_dir.mkdir(parents=True, exist_ok=True)
        
        for i, img_base64 in enumerate(images):
            img_data = base64.b64decode(img_base64)
            img = Image.open(BytesIO(img_data))
            
            filename = f"{name}_{i+1}.png"
            filepath = output_dir / filename
            img.save(filepath, format='PNG')
            
            file_size = filepath.stat().st_size
            print(f"  ✓ 已保存: {filepath} ({file_size:,} bytes)")
        
        elapsed = time.time() - start_time
        print(f"\n完成! 耗时: {elapsed:.1f}秒, 生成 {len(images)} 张")
        return True
        
    except requests.exceptions.Timeout:
        print("✗ 请求超时（可能生成时间过长）")
        return False
    except Exception as e:
        print(f"✗ 生成失败: {e}")
        import traceback
        traceback.print_exc()
        return False


def batch_generate(selected_names=None):
    """批量生成所有贴图"""
    print("=" * 60)
    print("AutoDoor Mod 贴图批量生成工具 (SD WebUI)")
    print("=" * 60)
    
    # 检查API连接
    if not check_api_connection():
        exit(1)
    
    # 显示当前模型
    get_current_model()
    
    # 确定要生成的贴图
    names_to_generate = selected_names or list(TEXTURE_PROMPTS.keys())
    
    results = {"success": [], "failed": []}
    
    for name in names_to_generate:
        if name not in TEXTURE_PROMPTS:
            print(f"\n⚠️  未知的贴图名称: {name}，跳过")
            continue
        
        config = TEXTURE_PROMPTS[name]
        success = generate_texture(name, config)
        
        if success:
            results["success"].append(name)
        else:
            results["failed"].append(name)
    
    # 汇总报告
    print("\n" + "=" * 60)
    print("批量生成完成！")
    print("=" * 60)
    print(f"成功: {len(results['success'])} 个")
    for name in results["success"]:
        print(f"  ✓ {name} → {OUTPUT_DIR / name}/")
    
    if results["failed"]:
        print(f"\n失败: {len(results['failed'])} 个")
        for name in results["failed"]:
            print(f"  ✗ {name}")
    
    print(f"\n输出目录: {OUTPUT_DIR}")
    print("下一步: 运行后处理脚本")
    print(f"  python tools/postprocess_textures.py --input-dir {OUTPUT_DIR}")
    
    return len(results["failed"]) == 0


def main():
    import argparse
    
    parser = argparse.ArgumentParser(description="AutoDoor Mod 贴图批量生成 (SD WebUI API)")
    parser.add_argument("--textures", nargs="+", help="指定要生成的贴图名称（默认全部）")
    parser.add_argument("--url", default=SD_WEBUI_URL, help=f"SD WebUI API地址 (默认: {SD_WEBUI_URL})")
    
    args = parser.parse_args()
    
    global SD_WEBUI_URL, API_TXT2IMG
    SD_WEBUI_URL = args.url
    API_TXT2IMG = f"{SD_WEBUI_URL}/sdapi/v1/txt2img"
    
    success = batch_generate(args.textures)
    exit(0 if success else 1)


if __name__ == "__main__":
    main()
