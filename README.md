# my blog

## 克隆仓库

1. 安装 hugo 扩展版
2. 克隆仓库 `git clone https://gitee.com/liwanggui/liwanggui.com.git --recurse-submodules`
3. 开始写作

**提示: ** 如果在克隆仓库时没有加 `--recurse-submodules` 选项，需要单独执行拉取主题子模块命令，命令如下

```bash
git submodule update --init --recursive
```

## 开始写文章

```bash
# 创建新文章
hugo new posts/<filename>.md

# 预览
hugo server

# 发布 -> public/
hugo
```

## 更新主题

```bash
# 可以将这个主题仓库添加为你的网站目录的子模块。
git submodule add https://github.com/HEIGE-PCloud/DoIt.git themes/DoIt

# 可以通过这条命令来将主题更新至最新版本。
git submodule update --remote --merge
```

## 图片引入

```
# 可以加标题
{{< figure src="/images/lighthouse.jpg" title="Lighthouse (figure)" >}}

# 点击可以悬浮放大
{{< image src="/images/lighthouse.jpg" caption="Lighthouse (`image`)" src_s="/images/lighthouse-small.jpg" src_l="/images/lighthouse-large.jpg" >}}

# 参数链接： https://hugoloveit.com/zh-cn/theme-documentation-extended-shortcodes/#image
```