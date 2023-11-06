# nvim-zh
neovim中文输入改进计划
目前neovim中文输入插件支持较差，可能的解决方案的线索都已经存在，但是要么需要手动编译，要么要自己配置一些文件目录，要么需要写vimscript来配置，如果想写中文markdown/org/norg，几乎是不可能的，本计划试图打破这个壁垒。

## 目标
- 尽量用纯lua编写
- 尽可能接近原生vim功能

## 中文输入法 input method
[flypy.nvim](https://github.com/noearc/flypy.nvim)

## 单词跳转和单词操作 motion & textobject
[jieba.nvim](https://github.com/noearc/jieba.nvim)

## 跳转和搜索 jumps & search
[leap-zh](https://github.com/noearc/leap-zh.nvim)
