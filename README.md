# neovim中文输入改进计划

目前 neovim 中文输入插件支持较差，在中文文本上使用 vim motion 是很尴尬的。可能的解决方案的线索都已经存在，但是要么需要手动编译，要么要自己配置一些文件目录，要么需要写 vimscript 来配置，如果想写中文 markdown/org/norg，体验都会很差，本计划希望通过填补空缺，并收录已有的解决方案，来打破这个壁垒。

## 目标

- 尽量用纯 lua 编写
- 尽可能接近原生 vim 功能

## 单词跳转和单词操作 motion & textobject

- 纯lua实现单词跳转和 textobject：[jieba.nvim](https://github.com/noearc/jieba.nvim) BY noearc
- python 实现单词跳转：[jieba.vim](https://github.com/kkew3/jieba.vim) BY kkew3
- cpp 实现单词跳转，需本地编译：[jieba_nvim](https://github.com/cathaysia/jieba_nvim) BY cathaysia

## 跳转和搜索 jumps & search

- [leap-zh.nvim](https://github.com/noearc/leap-zh.nvim) BY noearc
- [flash-zh.nvim](https://github.com/rainzm/flash-zh.nvim) BY rainzm
- [hop-zh-by-flypy](https://github.com/zzhirong/hop-zh-by-flypy) BY zzhirong
- [vim-easymotion-zh](https://github.com/zzhirong/vim-easymotion-zh) BY zzhirong
- [vim-PinyinSearch](https://github.com/ppwwyyxx/vim-PinyinSearch) BY ppwwyyxx

## 中文输入法 input method

- 基于 lsp 和 rime 的解决方案：[rime_ls](https://github.com/wlh320/rime-ls) BY @wlh320
- [rime_ls neovim 配置示例](https://github.com/wlh320/rime-ls/blob/master/doc/nvim.md)
- 基于 rime_ls 和 nvim-cmp 的插件：[cmp-lsp-rimels](https://github.com/liubianshi/cmp-lsp-rimels)
- 基于 lsp 的全拼解决方案：[ds-pinyin-lsp](https://github.com/iamcco/ds-pinyin-lsp) BY @iamcco
- 基于 nvim-cmp 的任意输入方式解决方案：[cmp-im](https://github.com/yehuohan/cmp-im) BY @yehuohan
- 基于 nvim-cmp 的小鹤音形，需本地编译：[nvim-cmp](https://github.com/wasden/cmp-flypy.nvim) BY wasden
- 基于 nvim-cmp 的小鹤音形，纯lua：[cmp-im-flypy](https://github.com/noearc/cmp-im-flypy) [WIP] BY noearc

## Linter

- 中文文本规范检查：[ChineseLinter.vim](https://github.com/wsdjeg/ChineseLinter.vim) BY wsdjeg
- 自动加入盘古之白：[pangu.nvim](https://github.com/noearc/pangu.nvim) BY noearc
- [zhlint](https://github.com/zhlint-project/zhlint) [未测试]
