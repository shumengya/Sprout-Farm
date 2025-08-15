#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
特殊农场系统性能监控脚本
用于监控特殊农场系统的资源使用情况
"""

import psutil
import time
import threading
from datetime import datetime

class SpecialFarmMonitor:
    def __init__(self):
        self.monitoring = False
        self.monitor_thread = None
        self.stats = {
            'cpu_usage': [],
            'memory_usage': [],
            'thread_count': [],
            'start_time': None
        }
    
    def start_monitoring(self, duration=60):
        """开始监控指定时间（秒）"""
        if self.monitoring:
            print("监控已在运行中")
            return
        
        self.monitoring = True
        self.stats['start_time'] = datetime.now()
        
        def monitor_loop():
            print(f"开始监控特殊农场系统性能 - {self.stats['start_time']}")
            print(f"监控时长: {duration} 秒")
            print("=" * 50)
            
            start_time = time.time()
            while self.monitoring and (time.time() - start_time) < duration:
                try:
                    # 获取当前进程信息
                    process = psutil.Process()
                    
                    # CPU使用率
                    cpu_percent = process.cpu_percent()
                    self.stats['cpu_usage'].append(cpu_percent)
                    
                    # 内存使用情况
                    memory_info = process.memory_info()
                    memory_mb = memory_info.rss / 1024 / 1024
                    self.stats['memory_usage'].append(memory_mb)
                    
                    # 线程数量
                    thread_count = process.num_threads()
                    self.stats['thread_count'].append(thread_count)
                    
                    # 实时显示
                    elapsed = int(time.time() - start_time)
                    print(f"\r[{elapsed:3d}s] CPU: {cpu_percent:5.1f}% | 内存: {memory_mb:6.1f}MB | 线程: {thread_count:2d}", end="", flush=True)
                    
                    time.sleep(1)
                    
                except Exception as e:
                    print(f"\n监控出错: {str(e)}")
                    break
            
            self.monitoring = False
            print("\n" + "=" * 50)
            self._print_summary()
        
        self.monitor_thread = threading.Thread(target=monitor_loop, daemon=True)
        self.monitor_thread.start()
    
    def stop_monitoring(self):
        """停止监控"""
        self.monitoring = False
        if self.monitor_thread:
            self.monitor_thread.join(timeout=2)
    
    def _print_summary(self):
        """打印监控摘要"""
        if not self.stats['cpu_usage']:
            print("没有收集到监控数据")
            return
        
        print("监控摘要:")
        print(f"监控时间: {self.stats['start_time']} - {datetime.now()}")
        print(f"数据点数: {len(self.stats['cpu_usage'])}")
        
        # CPU统计
        cpu_avg = sum(self.stats['cpu_usage']) / len(self.stats['cpu_usage'])
        cpu_max = max(self.stats['cpu_usage'])
        print(f"CPU使用率 - 平均: {cpu_avg:.1f}%, 最高: {cpu_max:.1f}%")
        
        # 内存统计
        mem_avg = sum(self.stats['memory_usage']) / len(self.stats['memory_usage'])
        mem_max = max(self.stats['memory_usage'])
        print(f"内存使用量 - 平均: {mem_avg:.1f}MB, 最高: {mem_max:.1f}MB")
        
        # 线程统计
        thread_avg = sum(self.stats['thread_count']) / len(self.stats['thread_count'])
        thread_max = max(self.stats['thread_count'])
        print(f"线程数量 - 平均: {thread_avg:.1f}, 最高: {thread_max}")
        
        # 性能评估
        print("\n性能评估:")
        if cpu_avg < 1.0:
            print("✓ CPU使用率很低，性能良好")
        elif cpu_avg < 5.0:
            print("✓ CPU使用率正常")
        else:
            print("⚠ CPU使用率较高，可能需要优化")
        
        if mem_avg < 50:
            print("✓ 内存使用量很低")
        elif mem_avg < 100:
            print("✓ 内存使用量正常")
        else:
            print("⚠ 内存使用量较高")
        
        if thread_max <= 10:
            print("✓ 线程数量合理")
        else:
            print("⚠ 线程数量较多，注意资源管理")

def main():
    """主函数"""
    print("特殊农场系统性能监控工具")
    print("使用说明:")
    print("1. 启动游戏服务器")
    print("2. 运行此监控脚本")
    print("3. 观察特殊农场系统的资源使用情况")
    print()
    
    monitor = SpecialFarmMonitor()
    
    try:
        # 监控60秒
        monitor.start_monitoring(60)
        
        # 等待监控完成
        while monitor.monitoring:
            time.sleep(1)
        
        print("\n监控完成")
        
    except KeyboardInterrupt:
        print("\n用户中断监控")
        monitor.stop_monitoring()
    except Exception as e:
        print(f"\n监控过程中出错: {str(e)}")
        monitor.stop_monitoring()

if __name__ == "__main__":
    main()