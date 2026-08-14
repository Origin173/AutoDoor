#!/usr/bin/env python3
"""
AutoDoor Mod 贴图后处理脚本
功能：批量去背景、缩放、格式转换、验证
依赖：Pillow (pip install Pillow)
用法：python postprocess_textures.py --input-dir ./raw_outputs --output-dir ./42/media/textures
"""

import argparse
import os
import sys
from pathlib import Path

try:
    from PIL import Image, ImageChops
except ImportError:
    print("错误: 需要安装Pillow库")
    print("运行: pip install Pillow")
    sys.exit(1)


# 贴图配置
TEXTURE_CONFIG = {
    "Item_RemoteDoorOpener": {"size": (128, 128), "type": "item_icon"},
    "Item_AutoDoorKey": {"size": (128, 128), "type": "item_icon"},
    "Item_AutoDoorMagazine": {"size": (128, 128), "type": "item_icon"},
    "Item_AutoGarageDoor": {"size": (128, 128), "type": "item_icon"},
    "Item_AutoFenceGate": {"size": (128, 128), "type": "item_icon"},
    "poster": {"size": (512, 256), "type": "banner"},
}


def remove_white_background(img, threshold=240):
    """
    将接近白色的背景转为透明
    threshold: 白色阈值，0-255，值越低越严格
    """
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    # 创建alpha通道掩码
    datas = img.getdata()
    new_data = []
    
    for item in datas:
        # 如果RGB都接近白色，设为透明
        if item[0] > threshold and item[1] > threshold and item[2] > threshold:
            new_data.append((255, 255, 255, 0))
        else:
            new_data.append(item)
    
    img.putdata(new_data)
    return img


def remove_background_by_color(img, bg_color=(255, 255, 255), tolerance=30):
    """
    按指定颜色去除背景（更精确）
    bg_color: RGB元组
    tolerance: 容差范围
    """
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    r, g, b = bg_color
    datas = img.getdata()
    new_data = []
    
    for item in datas:
        # 计算与背景色的距离
        distance = ((item[0] - r) ** 2 + (item[1] - g) ** 2 + (item[2] - b) ** 2) ** 0.5
        if distance < tolerance:
            new_data.append((r, g, b, 0))
        else:
            new_data.append(item)
    
    img.putdata(new_data)
    return img


def crop_to_content(img, padding=2):
    """裁剪到实际内容区域，保留少量边距"""
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    # 获取非透明区域的边界框
    bbox = img.getbbox()
    if bbox is None:
        return img
    
    left, upper, right, lower = bbox
    # 添加padding
    left = max(0, left - padding)
    upper = max(0, upper - padding)
    right = min(img.width, right + padding)
    lower = min(img.height, lower + padding)
    
    return img.crop((left, upper, right, lower))


def resize_to_target(img, target_size, preserve_aspect=False):
    """缩放到目标尺寸"""
    if preserve_aspect:
        # 保持宽高比，居中放置
        img.thumbnail(target_size, Image.LANCZOS)
        # 创建目标尺寸的画布
        canvas = Image.new('RGBA', target_size, (0, 0, 0, 0))
        offset = (
            (target_size[0] - img.width) // 2,
            (target_size[1] - img.height) // 2
        )
        canvas.paste(img, offset)
        return canvas
    else:
        # 强制拉伸到目标尺寸
        return img.resize(target_size, Image.LANCZOS)


def validate_texture(img, name, expected_size):
    """验证贴图是否符合要求"""
    issues = []
    
    # 检查尺寸
    if img.size != expected_size:
        issues.append(f"尺寸不正确: {img.size} != {expected_size}")
    
    # 检查是否有Alpha通道
    if img.mode != 'RGBA':
        issues.append(f"缺少Alpha通道: 当前模式={img.mode}")
    
    # 检查是否全透明（空图）
    alpha = img.split()[3]
    if alpha.getextrema()[1] == 0:
        issues.append("图像完全透明（可能抠图失败）")
    
    # 检查色彩饱和度（简单检测）
    rgb = img.convert('RGB')
    datas = list(rgb.getdata())
    avg_saturation = sum(
        max(r, g, b) - min(r, g, b) 
        for r, g, b in datas 
        if not (r > 240 and g > 240 and b > 240)  # 排除白色像素
    ) / max(len([d for d in datas if not (d[0] > 240 and d[1] > 240 and d[2] > 240)]), 1)
    
    if avg_saturation > 100:
        issues.append(f"色彩饱和度过高: {avg_saturation:.1f}（建议<80）")
    
    return issues


def process_single_texture(input_path, output_path, config):
    """处理单张贴图"""
    name = Path(input_path).stem
    print(f"\n{'='*60}")
    print(f"处理: {name}")
    print(f"输入: {input_path}")
    print(f"输出: {output_path}")
    
    try:
        # 打开图像
        img = Image.open(input_path)
        print(f"原始尺寸: {img.size}, 模式: {img.mode}")
        
        # 步骤1: 去除白色背景
        print("→ 去除白色背景...")
        img = remove_white_background(img, threshold=240)
        
        # 可选：如果效果不好，尝试更精确的颜色去除
        # img = remove_background_by_color(img, bg_color=(242, 242, 242), tolerance=20)
        
        # 步骤2: 裁剪到内容区域
        print("→ 裁剪到内容区域...")
        img = crop_to_content(img, padding=4)
        
        # 步骤3: 缩放到目标尺寸
        target_size = config["size"]
        print(f"→ 缩放到目标尺寸 {target_size}...")
        img = resize_to_target(img, target_size, preserve_aspect=False)
        
        # 步骤4: 确保RGBA模式
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        
        # 步骤5: 验证
        print("→ 验证贴图...")
        issues = validate_texture(img, name, target_size)
        if issues:
            print("⚠️  发现问题:")
            for issue in issues:
                print(f"   - {issue}")
        else:
            print("✓ 验证通过")
        
        # 步骤6: 保存
        output_path.parent.mkdir(parents=True, exist_ok=True)
        img.save(output_path, format='PNG', optimize=True)
        print(f"✓ 已保存: {output_path}")
        
        # 显示文件大小
        file_size = output_path.stat().st_size
        print(f"  文件大小: {file_size:,} bytes")
        
        return True
        
    except Exception as e:
        print(f"✗ 处理失败: {e}")
        import traceback
        traceback.print_exc()
        return False


def batch_process(input_dir, output_dir):
    """批量处理所有贴图"""
    input_path = Path(input_dir)
    output_path = Path(output_dir)
    
    if not input_path.exists():
        print(f"错误: 输入目录不存在: {input_dir}")
        sys.exit(1)
    
    # 创建输出目录
    output_path.mkdir(parents=True, exist_ok=True)
    
    results = {"success": [], "failed": []}
    
    print("=" * 60)
    print("AutoDoor Mod 贴图批量后处理")
    print("=" * 60)
    print(f"输入目录: {input_path}")
    print(f"输出目录: {output_path}")
    
    for name, config in TEXTURE_CONFIG.items():
        # 查找输入文件（支持多种扩展名）
        input_file = None
        for ext in ['.png', '.jpg', '.jpeg', '.webp']:
            candidate = input_path / f"{name}{ext}"
            if candidate.exists():
                input_file = candidate
                break
        
        if input_file is None:
            print(f"\n⚠️  未找到 {name} 的输入文件，跳过")
            results["failed"].append(name)
            continue
        
        # 确定输出路径
        output_file = output_path / f"{name}.png"
        
        # 处理
        success = process_single_texture(str(input_file), str(output_file), config)
        if success:
            results["success"].append(name)
        else:
            results["failed"].append(name)
    
    # 汇总报告
    print("\n" + "=" * 60)
    print("处理完成！")
    print("=" * 60)
    print(f"成功: {len(results['success'])} 张")
    for name in results["success"]:
        print(f"  ✓ {name}")
    
    if results["failed"]:
        print(f"\n失败: {len(results['failed'])} 张")
        for name in results["failed"]:
            print(f"  ✗ {name}")
    
    return len(results["failed"]) == 0


def main():
    parser = argparse.ArgumentParser(description="AutoDoor Mod 贴图后处理工具")
    parser.add_argument("--input-dir", default="./raw_outputs", help="AI生成图的输入目录")
    parser.add_argument("--output-dir", default="./42/media/textures", help="处理后贴图的输出目录")
    parser.add_argument("--single", type=str, help="只处理单个文件（文件名，不含扩展名）")
    
    args = parser.parse_args()
    
    if args.single:
        # 单文件处理模式
        name = args.single
        if name not in TEXTURE_CONFIG:
            print(f"错误: 未知的贴图名称 '{name}'")
            print(f"可用名称: {list(TEXTURE_CONFIG.keys())}")
            sys.exit(1)
        
        input_dir = Path(args.input_dir)
        output_dir = Path(args.output_dir)
        
        # 查找输入文件
        input_file = None
        for ext in ['.png', '.jpg', '.jpeg', '.webp']:
            candidate = input_dir / f"{name}{ext}"
            if candidate.exists():
                input_file = candidate
                break
        
        if input_file is None:
            print(f"错误: 在 {input_dir} 中未找到 {name}.*")
            sys.exit(1)
        
        output_file = output_dir / f"{name}.png"
        success = process_single_texture(str(input_file), str(output_file), TEXTURE_CONFIG[name])
        sys.exit(0 if success else 1)
    else:
        # 批量处理模式
        success = batch_process(args.input_dir, args.output_dir)
        sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
