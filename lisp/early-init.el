;. early-init.el
;.1. Header

;; early-init.el --- My early-init.el -*- lexical-binding: t -*-

;.2. 自動的なpackageのロードを無効にする

(setq package-enable-at-startup nil)

;.3. tab bar非表示

(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)

;.4. スタートアップメッセージを非表示
(setq inhibit-startup-message t)

;.5. 自動生成ファイルを無効にする
(setq make-backup-files nil)
(setq auto-save-default nil)
(setq auto-save-list-file-prefix nil)
(setq create-lockfiles nil)

;.6. time locale
(setq system-time-locale "C")

;.7. GC/Memory
(setq gc-cons-percentage 0.2
      gc-cons-threshold (* 128 1024 1024))
(add-hook 'focus-out-hook #'garbage-collect)

;(setq gc-cons-threshold (* 128 1024 1024))
;(setq garbage-collection-messages nil)

;.8. read-process

(setq read-process-output-max (* 8 1024 1024))

;.9. indent
(setq indent-tabs-mode nil)

;.10. ビープ音を消す
(setq ring-bell-function 'ignore)

;.11. デフォルトのpathをかえる
(setq default-directory "~/")
(setq command-line-default-directory "~/")

;.12. kill-ringのサイズを変更
(setq kill-ring-max 100000)
(custom-set-variables '(savehist-additional-variables '(kill-ring)))

;.13. 折り返ししない
(setq truncate-lines t)
(setq truncate-partial-width-windows t)

;.14. scratch buffer
(setq initial-scratch-message nil)
; org は早めにloadしておくと後が楽. ただ起動を早くしたい場合は止めることは可能.
;(setq initial-major-mode 'org-mode)
;;(setq initial-buffer-choice nil)
;;(setq rustic-load-optional-libraries nil)

;.15. x session resourcesを無視します
(advice-add 'x-apply-session-resources :override 'ignore)

;.16. history-delete-duplicates
(setq history-delete-duplicates t)

;.17. vc-follow-symlinks
(setq vc-follow-symlinks t)


;; Set part of theme at startup
(custom-set-faces
 '(default ((t (:background "#282a36" :foreground "#f8f8f2")))))
