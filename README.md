# nvim-zh
neovim中文输入改进计划
目前neovim中文输入插件支持较差，在中文文本上使用vim motion是很尴尬的。可能的解决方案的线索都已经存在，但是要么需要手动编译，要么要自己配置一些文件目录，要么需要写vimscript来配置，如果想写中文markdown/org/norg，体验都会很差，本计划希望通过填补空缺，并收录已有的解决方案，来打破这个壁垒。

## 目标
* 尽量用纯lua编写
* 尽可能接近原生vim功能

## 单词跳转和单词操作 motion & textobject
* [jieba.nvim](https://github.com/noearc/jieba.nvim)

## 跳转和搜索 jumps & search
* [leap-zh.nvim](https://github.com/noearc/leap-zh.nvim)

## 加入盘古之白 pangu.nvim
* [pangu.nvim](https://github.com/noearc/pangu.nvim)

## 中文输入法 input method [WIP]
* 基于lsp的全拼解决方案：[ds-pinyin-lsp](https://github.com/iamcco/ds-pinyin-lsp) BY @iamcco
* 基于nvim-cmp的任意输入方式解决方案：[cmp-im](https://github.com/yehuohan/cmp-im) BY @yehuohan
* [cmp-im-flypy](https://github.com/noearc/cmp-im-flypy) [WIP]

## Linter
* [ChineseLinter.vim](https://github.com/wsdjeg/ChineseLinter.vim)
* [zhlint](https://github.com/zhlint-project/zhlint) [未测试]
