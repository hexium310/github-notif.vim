# github_notif.vim

Display the notifications of GitHub on Neovim.
This plugin is yet only able to display.
The notifications is fetched each 60 seconds by default.

## Requirements

- Neovim

## Installation

```vim
Plug 'hexium310/github_notif.vim'
```

## Usage

```vim
" Start the job of getting the notifications
:NotifEnable

" Stop the job
:NotifDisable

" Open the notifications list
:NotifOpen

" Fetch forcibly the notifications
call github_notif#get({ 'force': v:true })
```

## Configuration

```vim
" The Personal Access Token for using GitHub API
let g:github_notif_token = 'XXXXXXXX'
" The interval of fetting
let g:github_notif_interval = 60
" The base url for using GitHub API
let g:github_notif_base_url = 'https://api.github.com/'
" If you fetch instantly the notifications
let g:github_notif_fetch_instantly = 1
```
