
# Vim Stealth Mode!
This plugin has purpose of maintain your files secures from sniches, spies or even from your cloud storage

My main reason for create this plugin is that I have some personal projects and I don't like the Idea that my content could be readed by some ramdom hacker or even the company behind your repository/CloudStorage.

### Installation 
This plugin works only with vim8, neovim does not suport the vim blofish method.

It will work once that you have configured and installed with your own choice method, like:

###### vimplug
	call plug#begin('~/.vim/plugged')
	Plug 'carlos-cabgj/vim-stealth-mode'
	call plug#end()

[TOC]
#### Configuration

###### Put in your .one-project this config, make shure that you have a .one-project in the root folder of your project

	"encryption": {
        "status"        : 0,
        "mode"          : 'fullDecrypt',
        "pathDecode"    : "/home/carlos/Desktop/stealth-dec/"
    }

- status : 0 for Off, 1 for On;
- mode : Defult 'fullDecrypt'. Work In Progress,
- pathDecode : Path to decode your project

### How
Every time that you enter in you project you will be requested to type the salt and after type your password and bang! you now can use this plugin in your project.

Every time the you open you a new file, your uncrypted content will be there, when you save you file the content will be encoded with blowfish2 ( vim blowfish ).

### Commands
- **OneProjectAddPassword**
	If you want to change your password.
	Caution if your actual content is already encrypted this will mess with you content.
- **OneProjectDecrypt**
	Use to decrypt your entire project to some other location defined in pathDecode.
- **OneProjectEncrypt**
	Use to encrypt your entire project with your actual salt and password, so you will not need to open every single file.


