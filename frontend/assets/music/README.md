# 背景音乐资源说明

请将你拥有授权的背景音乐文件放在本目录下，并使用以下文件名：

| 场景 | 文件名 | 对应需求 |
| --- | --- | --- |
| 启动/主菜单默认背景音乐 | `menu_yungongxunyin_new.ogg` | 《黑神话》风格 / 《云宫迅音》新版，低音量、舒缓 |
| 小兵阶段 | `stage_soldier_ganwenlu.ogg` | 敢问路在何方（改版） |
| 精英怪阶段 | `stage_elite_chengwang.ogg` | 称王称圣任纵横（开场主题曲） |
| 大妖怪阶段 | `stage_boss_kanjian.ogg` | 陈鸿宇 - 看见（黑风山片尾曲） |

> 版权提醒：这些曲目通常受版权保护，请仅使用已购买、已授权或你有权使用的音频文件。
>
> 当前 `MusicManager.gd` 默认引用 `.ogg`。如果你使用 `.mp3` 或 `.wav`，请同步修改：
> `frontend/scripts/core/MusicManager.gd` 中的 `MENU_MUSIC_PATH` 和 `STAGE_MUSIC_PATHS`。
