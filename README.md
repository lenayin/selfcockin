# self_checkin

上海自考英语（专升本）学习打卡 App，支持单词和词组混合学习、闪卡复习、四级评价、连续打卡、学习统计以及本地学习数据管理。

## 环境准备

安装 Flutter 依赖：

```bash
flutter pub get
```

新年度词库导入脚本使用 Python 和 `openpyxl`。首次使用前安装依赖：

```bash
python3 -m pip install openpyxl
```

## 新年度 Excel 导入

已支持通过命令行参数导入新的年度 Excel 词库。Excel 文件可以放在项目目录中，也可以使用绝对路径。

### Excel 格式要求

工作簿必须包含以下工作表：

- `高频单词(900)`：单词、音标、词性、释义、搭配和例句
- `高频词组搭配`：词组分类、词组、释义和例句
- `考试信息与备考指南`：考试信息和备考说明

脚本会自动：

- 合并重复的单词和词组条目
- 忽略空行，处理空字段
- 合并重复条目的释义、词性和搭配
- 读取本地中文例句翻译
- 生成 App 使用的 `assets/data/vocab_seed.json`

### 导入命令

```bash
python3 tool/generate_vocab_seed.py \
  --source 新年度词库.xlsx \
  --output assets/data/vocab_seed.json \
  --translations assets/data/example_translations_zh.json
```

命令行参数：

- `--source`：年度 Excel 文件路径
- `--output`：词库 JSON 输出路径
- `--translations`：中文例句翻译 JSON 文件路径

查看所有参数：

```bash
python3 tool/generate_vocab_seed.py --help
```

如果未传入参数，脚本会使用代码中配置的默认年度 Excel、JSON 输出和翻译文件路径。

### 生成例句中文翻译

如新词库包含未翻译的英文例句，可以运行以下命令生成本地中文翻译：

```bash
python3 tool/generate_example_translations.py \
  --kind all \
  --email 你的有效邮箱
```

`--kind` 可选值为 `all`、`word`、`phrase`，分别表示全部、单词例句或词组例句。`--email` 可选，用于提高 MyMemory 翻译接口的请求额度。翻译结果会保存到：

```text
assets/data/example_translations_zh.json
```

生成翻译后，再重新运行词库导入命令，将翻译写入词库 JSON。

## 构建和测试

导入新词库后，建议执行：

```bash
flutter pub get
flutter test
flutter build apk --debug
```

运行 Android 模拟器：

```bash
flutter run -d emulator-5554
```
