(package-initialize)

; take さんに感謝. https://zenn.dev/takeokunn/articles/56010618502ccc

; native-comp warning no report
(setq native-comp-async-report-warnings-errors 'silent)
; no beep
(setq ring-bell-function 'ignore)
; remove file to trashbox
(setq delete-by-moving-to-trash t)

; officeならプロキシ環境とする.代わりにwindowsならproxy設定.
(when (equal system-type 'windows-nt)
  (setq url-proxy-services
      '(("http" . "172.27.12.7:12080")
        ("https" . "172.27.12.7:12080"))))

; 偉大な先人達に感謝.
(setq package-archives
      '(("gnu" . "http://elpa.gnu.org/packages/")
        ("melpa" . "http://melpa.org/packages/")
        ("org" . "http://orgmode.org/elpa/")))
;frame size and position


; emacsclient でopen出来るようにserverを起動.
(server-start)

; 起動時間計測
(defconst my/loading-profile-p nil
  "If non-nil, use built-in profiler.el.")
(defconst my/enable-profile nil
  "If true, enable profile")
(defconst my/enable-c-h-backspace nil
  "If true, enable C-h backspace")

(defmacro when-darwin (&rest body)
  (when (string= system-type "darwin")
    `(progn ,@body)))

;.2. when-darwin-not-window-system
(defmacro when-darwin-not-window-system (&rest body)
  (when (and (string= system-type "darwin")
             window-system)
    `(progn ,@body)))

;.3. when-guix
(defmacro when-guix (&rest body)
  (when (string= system-type "guix")
    `(progn ,@body)))

;. Boot
;.1. user
(setq user-full-name "bito")
(setq user-mail-address "ronaldobraziljp@yahoo.co.jp")

;.2. profile
(when my/enable-profile
  (require 'profiler)
  (profiler-start 'cpu))

;.3. Magic File Name を一時的に無効にする
(defconst my/saved-file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)

;.4. 起動時間計測
(defconst my/before-load-init-time (current-time))

;;;###autoload
(defun my/load-init-time ()
  "Loading time of user init files including time for `after-init-hook'."
  (let ((time1 (float-time
                (time-subtract after-init-time my/before-load-init-time)))
        (time2 (float-time
                (time-subtract (current-time) my/before-load-init-time))))
    (message (concat "Loading init files: %.0f [msec], "
                     "of which %.f [msec] for `after-init-hook'.")
             (* 1000 time1) (* 1000 (- time2 time1)))))
(add-hook 'after-init-hook #'my/load-init-time t)
(defvar my/tick-previous-time my/before-load-init-time)

;;;###autoload
(defun my/tick-init-time (msg)
  "Tick boot sequence at loading MSG."
  (when my/loading-profile-p
    (let ((ctime (current-time)))
      (message "---- %5.2f[ms] %s"
               (* 1000 (float-time
                        (time-subtract ctime my/tick-previous-time)))
               msg)
      (setq my/tick-previous-time ctime))))

(defun my/emacs-init-time ()
  "Emacs booting time in msec."
  (interactive)
  (message "Emacs booting time: %.0f [msec] = `emacs-init-time'."
           (* 1000
              (float-time (time-subtract
                           after-init-time
                           before-init-time)))))

(add-hook 'after-init-hook #'my/emacs-init-time)


;.5. async load
(defvar my/delayed-priority-high-configurations '())
(defvar my/delayed-priority-high-configuration-timer nil)

(defvar my/delayed-priority-low-configurations '())
(defvar my/delayed-priority-low-configuration-timer nil)

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq my/delayed-priority-high-configuration-timer
                  (run-with-timer
                   0.1 0.001
                   (lambda ()
                     (if my/delayed-priority-high-configurations
                         (let ((inhibit-message t))
                           (eval (pop my/delayed-priority-high-configurations)))
                       (progn
                         (cancel-timer my/delayed-priority-high-configuration-timer))))))
            (setq my/delayed-priority-low-configuration-timer
                  (run-with-timer
                   0.3 0.001
                   (lambda ()
                     (if my/delayed-priority-low-configurations
                         (let ((inhibit-message t))
                           (eval (pop my/delayed-priority-low-configurations)))
                       (progn
                         (cancel-timer my/delayed-priority-low-configuration-timer))))))))

(defmacro with-delayed-execution-priority-high (&rest body)
  (declare (indent 0))
  `(setq my/delayed-priority-high-configurations
         (append my/delayed-priority-high-configurations ',body)))

(defmacro with-delayed-execution (&rest body)
  (declare (indent 0))
  `(setq my/delayed-priority-low-configurations
         (append my/delayed-priority-low-configurations ',body)))

;.6. autoload-if-found
;;;###autoload
(defun autoload-if-found (functions file &optional docstring interactive type)
  "set autoload iff. FILE has found."
  (when (locate-library file)
    (dolist (f functions)
      (autoload f file docstring interactive type))
    t))


;.7. common lispを使う
(eval-and-compile
  (setq byte-compile-warnings '(cl-functions))
  (require 'cl-lib nil t))
(with-delayed-execution-priority-high
  (message "Install cl-lib...")
  (require 'cl-lib))

; ウインドウポジション、サイズ(windows position, size)
(when (eq system-type 'gnu/linux)
  (set-frame-size (selected-frame) 93 56)
  (set-frame-position (selected-frame) 915 28))

; ~/.emacs.d/lisp 直下を load-path に追加
(let ((default-directory (locate-user-emacs-file "./lisp")))
  (add-to-list 'load-path default-directory)
  (normal-top-level-add-subdirs-to-load-path))


;.8. el-clone
(eval-when-compile
  (unless (file-directory-p (locate-user-emacs-file "elpa/el-clone"))))
  ;;; MEMO emacs 設定ファイルをgithub管理するなら以下のように.
  ;;;  (package-vc-install "https://github.com/takeokunn/el-clone.git")))

(eval-and-compile
  (add-to-list 'load-path (locate-user-emacs-file "elpa/el-clone"))
  (require 'el-clone))


;; カーソル移動を論理行にする
(setq line-move-visual nil)

;. Basic
;.1. 末尾のスペースを可視化する
(with-delayed-execution
  (message "Install disable-show-trailing-whitespace...")

  (defun my/disable-show-trailing-whitespace ()
    (setq show-trailing-whitespace nil))

  (with-eval-after-load 'comint
    (add-hook 'comint-mode-hook #'my/disable-show-trailing-whitespace))

  (with-eval-after-load 'esh-mode
    (add-hook 'eshell-mode-hook #'my/disable-show-trailing-whitespace))

  (with-eval-after-load 'eww
    (add-hook 'eww-mode-hook #'my/disable-show-trailing-whitespace))

  (with-eval-after-load 'minibuffer
    (add-hook 'minibuffer-inactive-mode-hook #'my/disable-show-trailing-whitespace))

  (with-eval-after-load 'dashboard
    (add-hook 'dashboard-mode-hook #'my/disable-show-trailing-whitespace))

  (with-eval-after-load 'simple
    (add-hook 'fundamental-mode-hook #'my/disable-show-trailing-whitespac))
  )


;.2. 行番号を表示する
(with-delayed-execution
  (message "Install display-line-numbers...")
  (autoload-if-found '(global-display-line-numbers-mode) "display-line-numbers" nil t)
  (global-display-line-numbers-mode)

  (with-eval-after-load 'display-line-numbers
    (setq display-line-numbers-grow-only nil)
    ;(setq display-line-numbers-width 5)
    ))

;.3. C-kで行削除
(with-eval-after-load 'simple
  (setq kill-whole-line t))

;.4. カッコの中をハイライトする
(with-delayed-execution
  (message "Install show-paren-mode...")
  (show-paren-mode t)
  (with-eval-after-load 'paren
    (setq show-paren-style 'parenthesis)))

;.6. coding system
;; language and locale
(setq system-time-locale "C")
(set-language-environment "Japanese")

;; coding system
(set-default-coding-systems 'utf-8-unix)
(prefer-coding-system 'utf-8-unix)
(set-selection-coding-system 'utf-8-unix)

;; prefer-coding-system take effect equally to follows
(set-buffer-file-coding-system 'utf-8-unix)
(set-file-name-coding-system 'utf-8-unix)
(set-terminal-coding-system 'utf-8-unix)
(set-keyboard-coding-system 'utf-8-unix)
(setq locale-coding-system 'utf-8-unix)

;.7. global-auto-revert-mode
(with-delayed-execution
  (message "Install global-auto-revert-mode...")
  (global-auto-revert-mode t))

;.8. yes/no to y/n
(with-delayed-execution
  (fset 'yes-or-no-p 'y-or-n-p))

; 基本的なキーマップ
(global-set-key (kbd "C-?") #'help-command)
(global-set-key (kbd "M-¥") #'(lambda () (interactive) (insert "\\")))
(global-set-key (kbd "C-z") #'undo)
(global-set-key (kbd "C-a") #'back-to-indentation)
(global-set-key (kbd "C-c i") #'find-function)
(global-set-key (kbd "C-c C-o") #'org-open-at-point)
(global-set-key (kbd "C-x C-o") #'other-window)
(global-set-key (kbd "C-x :") #'goto-line)
(global-set-key (kbd "M-h") #'backward-kill-word)
(global-set-key (kbd "C-x l") 'next-buffer)
(global-set-key (kbd "C-x p") 'previous-buffer)
(global-set-key (kbd "C-x C-b") #'switch-to-buffer)
(global-set-key (kbd "C-x C-k") nil)
(global-set-key (kbd "C-x C-n") nil)
(global-set-key (kbd "C-x f") 'recentf-open-files)


;.10. minibuffer
(define-key minibuffer-mode-map (kbd "C-h") #'delete-backward-char)
(define-key minibuffer-mode-map (kbd "M-h") #'backward-kill-word)
(define-key minibuffer-mode-map (kbd "C-j") #'exit-minibuffer)
(define-key minibuffer-mode-map (kbd "M-RET") #'exit-minibuffer)

;.11. savehistを有効にする
(with-delayed-execution-priority-high
  (message "Install savehist...")
  (savehist-mode 1))



;; ;; minibuffer用
;; (define-key minibuffer-local-completion-map "\C-w" 'backward-kill-word)

;; ;10 カーソル位置の単語を削除
;; (defun kill-word-at-point ()
;;   (interactive)
;;   (let ((char (char-to-string (char-after (point)))))
;;     (cond
;;      ((string= " " char) (delete-horizontal-space))
;;      ((string-match "[\t\n -@\[-`{-~]" char) (kill-word 1))
;;      (t (forward-char) (backward-word) (kill-word 1)))))
;; (global-set-key "\M-d" 'kill-word-at-point)

;; ;- リスト11 kill-lineで行が連結したときにインデントを減らす
;; (defadvice kill-line (before kill-line-and-fixup activate)
;;   (when (and (not (bolp)) (eolp))
;;     (forward-char)
;;     (fixup-whitespace)
;;     (backward-char)))



;.13. pluginをnative compする
(with-eval-after-load 'comp
  (setq native-comp-async-jobs-number 8)
  (setq native-comp-speed 2)
  (setq native-comp-always-compile t)
  (defun my/native-comp-packages ()
    (interactive)
    (native-compile-async "~/.emacs.d/init.el")
    (native-compile-async "~/.emacs.d/early-init.el")
    (native-compile-async "~/.emacs.d/popup-autoloads.el")
    (native-compile-async "~/.emacs.d/popup-pkg.el")
    (native-compile-async "~/.emacs.d/popup.el")
    (native-compile-async "~/.emacs.d/mozc-popup-autoloads.el")
    (native-compile-async "~/.emacs.d/mozc-popup-pkg.el")
    (native-compile-async "~/.emacs.d/mozc-popup.el")
    (native-compile-async "~/.emacs.d/el-clone" 'recursively)
    (native-compile-async "~/.emacs.d/elpa" 'recursively)))

;.14. native compを無効にする
(with-eval-after-load 'comp
  (setq package-native-compile nil))

;.15. native compのwarningを抑える
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(goggles-pulse-delay 0.1)
 '(goggles-pulse-iterations 2)
 '(initial-buffer-choice nil)
 '(package-selected-packages nil)
 '(savehist-additional-variables '(kill-ring))
 '(warning-suppress-types '((comp))))

;.16. 同一bufferの名前を変える
(with-eval-after-load 'uniquify
  (setq uniquify-buffer-name-style 'post-forward-angle-brackets))

;.17. scratch,message バッファを killできないようにする
(with-current-buffer "*scratch*"
  (emacs-lock-mode 'kill))

(with-current-buffer "*Messages*"
  (emacs-lock-mode 'kill))

;; scratch バッファの内容をファイルに書き出して保持する
(defun save-scratch-data ()
  (let ((str (progn
               (set-buffer (get-buffer "*scratch*"))
               (buffer-substring-no-properties
                (point-min) (point-max))))
        (file "~/.emacs.d/.scratch"))
    (if (get-file-buffer (expand-file-name file))
        (setq buf (get-file-buffer (expand-file-name file)))
      (setq buf (find-file-noselect file)))
    (set-buffer buf)
    (erase-buffer)
    (insert str)
    (save-buffer)
    (kill-buffer buf)))

(defadvice save-buffers-kill-emacs
  (before save-scratch-buffer activate)
  (save-scratch-data))

(defun read-scratch-data ()
  (let ((file "~/.emacs.d/.scratch"))
    (when (file-exists-p file)
      (set-buffer (get-buffer "*scratch*"))
      (erase-buffer)
      (insert-file-contents file))
    ))

(read-scratch-data)

;.18. 日時表示
(with-eval-after-load 'time
  (setq display-time-24hr-format t)
  (setq display-time-day-and-date t))

; mozcの設定 
(require 'mozc)
(require 'mozc-popup) ;;
(require 'mozc-cursor-color)
(set-language-environment "Japanese")
(setq default-input-method "japanese-mozc")
(setq mozc-candidate-style 'popup)
; mozc カーソルカラーを設定する
(setq mozc-cursor-color-alist '((direct        . "LightYellow")
                                (read-only     . "yellow")
                                (hiragana      . "green")
                                (full-katakana . "goldenrod")
                                (half-ascii    . "dark orchid")
                                (full-ascii    . "orchid")
                                (half-katakana . "dark goldenrod")))

; 全角半角キーで on/off
(global-set-key [zenkaku-hankaku] 'toggle-input-method)
; 変換キーでon
(global-set-key [henkan]
		(lambda () (interactive)
		  (when (null current-input-method) (toggle-input-method))))
; 無変換キーでon
(global-set-key [muhenkan]
		(lambda () (interactive)
		  (inactivate-input-method)))
; 全角半角キーと無変換キーのキーイベントを横取りする
(defadvice mozc-handle-event (around intercept-keys (event))
  "Intercept keys muhenkan and zenkaku-hankaku, before passing keys
to mozc-server (which the function mozc-handle-event does), to
properly disable mozc-mode."
  (if (member event (list 'zenkaku-hankaku 'muhenkan))
      (progn
	(mozc-clean-up-session)
	(toggle-input-method))
    (progn ;(message "%s" event) ;debug
      ad-do-it)))
(ad-activate 'mozc-handle-event)


;.20. warning
(setq display-warning-minimum-level :error)

;.21. キーコマンド入力中に入力過程をミニバッファに反映する
(setq echo-keystrokes 0.1)

;.22. recursive minibuffers
(setq enable-recursive-minibuffers t)

;.23. inhibit-compacting-font-caches
(setq inhibit-compacting-font-caches t)

;.24. save-place-mode
(with-delayed-execution
  (save-place-mode 1))

;.25. enable-local-variables
(setq enable-local-variables :all)



;.27. tab-width
(setq tab-width 4)

;.28. indentはspaceにする
(setq-default indent-tabs-mode nil)

;.29. 検索で大文字小文字を区別しない
(setq read-file-name-completion-ignore-case t)
(setq read-buffer-completion-ignore-case t)
(setq completion-ignore-case t)

; async
(eval-when-compile
  (el-clone :repo "jwiegley/emacs-async"))

(with-delayed-execution-priority-high
  (message "Install async...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/emacs-async")))


; thierryvolpiatto/wfnames
(eval-when-compile
  (el-clone :repo "thierryvolpiatto/wfnames"))

(with-delayed-execution-priority-high
  (message "Install thierryvolpiatto/wfnames...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/wfnames")))


;6.10. dash
(eval-when-compile
  (el-clone :repo "magnars/dash.el"))

(with-delayed-execution-priority-high
  (message "Install dash...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/dash")))



;6.17. f
(eval-when-compile
  (el-clone :repo "rejeep/f.el"))

(with-delayed-execution-priority-high
  (message "Install f...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/f")))


;6.48. s
(eval-when-compile
  (el-clone :repo "magnars/s.el"))

(with-delayed-execution-priority-high
  (message "Install s...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/s")))


;6.58. ts
(eval-when-compile
  (el-clone :repo "alphapapa/ts.el"))

(with-delayed-execution-priority-high
  (message "Install ts...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/ts")))



;6.25. ht
(eval-when-compile
  (el-clone :repo "Wilfred/ht.el"))

(with-delayed-execution-priority-high
  (message "Install ht...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/ht")))


; auto-complete/popup-el
;; (eval-when-compile
;;   (el-clone :repo "auto-complete/popup.el"))

;; (with-delayed-execution-priority-high
;;   (message "Install auto-complete/popup-el...")
;;   (add-to-list 'load-path (locate-user-emacs-file "el-clone/popup")))


(eval-when-compile
  (el-clone :repo "milkypostman/powerline"))

(with-delayed-execution-priority-high
  (message "Install powerline...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/powerline")))

;.4. c++-mode

(with-eval-after-load 'c++-mode
  (add-hook 'c++-mode-hook #'lsp-bridge-mode))

;.5. c-mode

(with-eval-after-load 'cc-mode
  (add-hook 'c-mode-hook #'lsp-bridge-mode))

;.9. flymake初期化 TODO errorが出る. at emacs 29, 30.50.
;(require 'flymake)
;(require 'flymake-proc)
;github.com/flymake/emacs-flymake/blob/master/flymake.el

;(eval-when-compile
;  (el-clone :repo "flymake/emacs-flymake/blob/master"))

;(with-delayed-execution
;  (message "Install flymake...")
;  (add-to-list 'load-path (locate-user-emacs-file "el-clone/flymake")))

  
;.9. cmake-mode
(eval-when-compile
  (el-clone :repo "emacsmirror/cmake-mode"))

(with-delayed-execution
  (message "Install cmake...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/cmake-mode"))

  (autoload-if-found '(cmake-mode) "cmake-mode" nil t)
  (add-to-list 'auto-mode-alist '("\\.cmake$" . cmake-mode)))


;.13. csharp-mode
(eval-when-compile
  (el-clone :repo "emacs-csharp/csharp-mode"))

(with-delayed-execution
  (message "Install csharp-mode...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/csharp-mode"))

  (autoload-if-found '(csharp-mode) "csharp-mode" nil t)
  (add-to-list 'auto-mode-alist '("\\.cs$" . csharp-mode)))




;.15. csv-mode
(eval-when-compile
  (el-clone :repo "emacsmirror/csv-mode"))

(with-delayed-execution
  (message "Install csv-mode...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/csv-mode"))

  (autoload-if-found '(csv-mode) "csv-mode" nil t)
  (push '("\\.csv$" . csv-mode) auto-mode-alist))



;.44. java-mode
(with-delayed-execution
  (message "Install java-mode...")
  (autoload-if-found '(java-mode) "java-mode" nil t)
  (add-to-list 'auto-mode-alist '("\\.java$" . java-mode)))



;.46. json-mode
(eval-when-compile
  (el-clone :repo "Sterlingg/json-snatcher")
  (el-clone :repo "joshwnj/json-mode"))

(with-delayed-execution
  (message "Install json-mode...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/json-snatcher"))
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/json-mode"))

  (autoload-if-found '(json-mode) "json-mode" nil t)

  (add-to-list 'auto-mode-alist '("\\.json$" . json-mode))
  (add-to-list 'auto-mode-alist '("\\.textlintrc$" . json-mode))
  (add-to-list 'auto-mode-alist '("\\.prettierrc$" . json-mode))
  (add-to-list 'auto-mode-alist '("\\.markuplintrc$" . json-mode))

  (with-eval-after-load 'json-mode
    (add-hook 'json-mode-hook #'flycheck-mode)))

; typescript-mode
(autoload-if-found '(typescript-mode) "typescript-mode" nil t)
;; for ts/deno
(add-to-list 'auto-mode-alist '("\\.ts$" . typescript-mode))
;; for tsx
(define-derived-mode typescript-tsx-mode typescript-mode "tsx")
(add-to-list 'auto-mode-alist '("\\.jsx$" . typescript-tsx-mode))
(add-to-list 'auto-mode-alist '("\\.tsx$" . typescript-tsx-mode))

;.61. pcap-mode
(eval-when-compile
  (el-clone :repo "orgcandman/pcap-mode"))

(with-delayed-execution
  (message "Install pcap-mode...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/pcap-mode"))

  (autoload-if-found '(pcap-mode) "pcap" nil t)

  (add-to-list 'auto-mode-alist '("\\.pcap$" . pcap-mode)))



;.66. plantuml-mode
(eval-when-compile
  (el-clone :repo "skuro/plantuml-mode"))

(with-delayed-execution
  (message "Install plantuml-mode...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/plantuml-mode"))

  (autoload-if-found '(plantuml-mode) "plantuml-mode" nil t)

  (add-to-list 'auto-mode-alist '("\\.pu$" . plantuml-mode)))

;.67. protobuf-mode
(eval-when-compile
  (el-clone :repo "protocolbuffers/protobuf"))

(with-delayed-execution
  (message "Install protobuf-mode...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/protobuf/editors"))

  (autoload-if-found '(protobuf-mode) "protobuf-mode" nil t)

  (add-to-list 'auto-mode-alist '("\\.proto\\'" . protobuf-mode)))


;.1.4. popwin
(eval-when-compile
  (el-clone :repo "emacsorphanage/popwin"))

(with-delayed-execution
  (message "Install popwin...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/popwin"))

  (autoload-if-found '(popwin-mode) "popwin" nil t)

  (popwin-mode 1))

;.1.5. whitespace
(with-delayed-execution
  (message "Install whitespace...")
  (when (autoload-if-found '(global-whitespace-mode) "whitespace" nil t)
    (if window-system
        (global-whitespace-mode 1)))
  (with-eval-after-load 'whitespace
    (setq whitespace-style '(face tabs tab-mark spaces space-mark))
    (setq whitespace-display-mappings '((space-mark ?\u3000 [?\u25a1])
                                        (tab-mark ?\t [?\xBB ?\t] [?\\ ?\t])))))



;.2.1. flycheck
(eval-when-compile
  (el-clone :repo "flycheck/flycheck"))

(with-delayed-execution
  (message "Install flycheck...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/flycheck"))

  (autoload-if-found '(flycheck-mode flycheck-define-checker) "flycheck" nil t))

;.2.2. flycheck-textlint
(with-delayed-execution
  (flycheck-define-checker textlint
    "A linter for prose."
    :command ("npx" "textlint" "--format" "unix" source-inplace)
    :error-patterns
    ((warning line-start (file-name) ":" line ":" column ": "
              (id (one-or-more (not (any " "))))
              (message (one-or-more not-newline)
                       (zero-or-more "\n" (any " ") (one-or-more not-newline)))
              line-end))
    :modes (org-mode))
  (with-eval-after-load 'flycheck
    (add-to-list 'flycheck-checkers 'textlint)))


;.4.1. ansi-color
(with-delayed-execution
  (message "Install ansi-color...")
  (autoload 'ansi-color-for-comint-mode-on "ansi-color" "Set `ansi-color-for-comint-mode' to t." t)
  (autoload-if-found '(ansi-color-for-comint-mode-on) "ansi-color" nil t)

  (with-eval-after-load 'shell-mode
    (add-hook 'shell-mode-hook #'ansi-color-for-comint-mode-on))

  (with-eval-after-load 'compile
    (add-hook 'compilation-filter-hook #'(lambda ()
                                           (ansi-color-apply-on-region (point-min) (point-max))))))

;.4.2. highlight-indent-guides
(eval-when-compile
  (el-clone :repo "DarthFennec/highlight-indent-guides"))

(with-delayed-execution
  (message "Install highlight-indent-guides...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/highlight-indent-guides"))

  (autoload-if-found '(highlight-indent-guides-mode) "highlight-indent-guides" nil t)

  (with-eval-after-load 'yaml-mode
    (add-hook 'yaml-mode-hook 'highlight-indent-guides-mode))

  (with-eval-after-load 'highlight-indent-guides
    (setq highlight-indent-guides-responsive 'stack)
    (setq highlight-indent-guides-method 'bitmap)))

;.4.3. hl-todo
(eval-when-compile
  (el-clone :repo "tarsius/hl-todo"))

(with-delayed-execution
  (message "Install hl-todo...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/hl-todo"))

  (autoload-if-found '(global-hl-todo-mode) "hl-todo" nil t)

  (global-hl-todo-mode)

  (with-eval-after-load 'hl-todo
    (setq hl-todo-keyword-faces
          '(("HOLD" . "#d0bf8f")
            ("TODO" . "#cc9393")
            ("NOW" . "#dca3a3")
            ("SOMEDAY" . "#bfd9bf")
            ("WAIT" . "#7cb8bb")
            ("DONE" . "#afd8af")
            ("FIXME" . "#cc9393")))))


;.6. Completion
;.6.1. corfu

(eval-when-compile
  (el-clone :repo "minad/corfu"))

(with-delayed-execution
  (message "Install corfu...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/corfu"))
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/corfu/extensions"))

  (autoload-if-found '(global-corfu-mode) "corfu" nil t)

  (global-corfu-mode)

  (with-eval-after-load 'corfu
    (setq corfu-auto t)
    (setq corfu-auto-delay 0.2)
    (setq corfu-cycle t)
    (setq corfu-popupinfo-mode +1)
    (setq corfu-preselect 'valid)
    (setq corfu-on-exact-match nil))

  (with-eval-after-load 'indent
    (setq tab-always-indent 'complete)))

;.6.2. cape

(eval-when-compile
  (el-clone :repo "minad/cape"))

(with-delayed-execution
  (message "Install cape...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/cape"))

  (autoload-if-found '(cape-file
                       cape-dabbrev
                       cape-elisp-block
                       cape-history
                       cape-keyword) "cape" nil t)

  (with-eval-after-load 'minibuffer
    (add-to-list 'completion-at-point-functions #'cape-dabbrev)
    (add-to-list 'completion-at-point-functions #'cape-file)
    (add-to-list 'completion-at-point-functions #'cape-elisp-block)
    (add-to-list 'completion-at-point-functions #'cape-history)))

;.6.3. prescient

(eval-when-compile
  (el-clone :repo "radian-software/prescient.el"))

(with-delayed-execution
  (message "Install prescient...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/prescient"))

  (autoload-if-found '(prescient-persist-mode) "prescient" nil t)

  (prescient-persist-mode)

  (with-eval-after-load 'prescient
    (setq prescient-aggressive-file-save t)))

;.6.4. kind-icon

(eval-when-compile
  (el-clone :repo "jdtsmith/kind-icon"))

(with-delayed-execution
  (message "Install kind-icon...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/kind-icon"))

  (autoload-if-found '(kind-icon-margin-formatter) "kind-icon" nil t)

  (with-eval-after-load 'corfu
    (add-to-list 'corfu-margin-formatters #'kind-icon-margin-formatter)))

;.7. Cursor

;; ;.7.3. expand-region -> puniのexpand-regionへ
;; (eval-when-compile
;;   (el-clone :repo "magnars/expand-region.el"))
;; (with-delayed-execution
;;   (message "Install expand-region...")
;;   (add-to-list 'load-path (locate-user-emacs-file "el-clone/expand-region"))
;;   (autoload-if-found '(er/expand-region) "expand-region" nil t)
;;   (transient-mark-mode)
;;   (global-set-key (kbd "C-@") 'er/expand-region)
;;   (global-set-key (kbd "C-M-@") 'er/contract-region))


;.8. multiple-cursors
(eval-when-compile
  (el-clone :repo "magnars/multiple-cursors.el"))

(with-delayed-execution
  (message "Install multiple-cursors...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/multiple-cursors"))

  (autoload-if-found '(mc/mark-next-like-this mc/mark-previous-like-this mc/mark-all-like-this) "multiple-cursors" nil t)

  (global-set-key (kbd "C->") #'mc/mark-next-like-this)
  (global-set-key (kbd "C-<") #'mc/mark-previous-like-this)
  (global-set-key (kbd "C-c C-<") #'mc/mark-all-like-this))

;.8.1. subword

(with-delayed-execution
  (message "Install subword...")
  (autoload-if-found '(my/delete-forward-block) "subword" nil t)

  (global-set-key (kbd "M-d") #'my/delete-forward-block)

  (defun my/delete-forward-block ()
    (interactive)
    (if (eobp)
        (message "End of buffer")
      (let* ((syntax-move-point
              (save-excursion
                (skip-syntax-forward (string (char-syntax (char-after))))
                (point)))
             (subword-move-point
              (save-excursion
                (subword-forward)
                (point))))
        (kill-region (point) (min syntax-move-point subword-move-point))))))


;.11. EWW
;.11.1. basic

(with-delayed-execution
  (message "Install eww...")

  (defun my/eww-rename-buffer ()
    "Rename the name of current EWW buffer."
    (let* ((title (plist-get eww-data :title))
           (url (file-name-base (eww-current-url)))
           (buffer-name (or (if (and title (> (length title) 0))
                                title
                              nil)
                            url "")))
      (rename-buffer (format "eww: %s" buffer-name) t)))

  ;; config
  (with-eval-after-load 'eww
    (setq eww-header-line-format nil)
    ; google 検索でjavascript有効にしてください、と表示されるようになったため、
    ;duckduckgoに
    ;(setq eww-search-prefix "http://www.google.co.jp/search?q=")
    )

  ;; keybind
  (with-eval-after-load 'eww
    (define-key eww-mode-map (kbd "C") #'eww-set-character-encoding)
    (define-key eww-mode-map (kbd "C-j") #'eww-follow-link)
    (define-key eww-mode-map (kbd "T") #'eww-goto-title-heading)
    (define-key eww-mode-map (kbd "T") #'eww-goto-title-heading))

  ;; hooks
  (with-eval-after-load 'eww
    (add-hook 'eww-after-render #'my/eww-rename-buffer)))

;.11.2. eww-lnum

(eval-when-compile
  (el-clone :repo "m00natic/eww-lnum"))

(with-delayed-execution
  (message "Install eww-lnum...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/eww-lnum"))

  (autoload-if-found '(eww-lnum-follow eww-lnum-universal) "eww-lnum" nil t)

  (with-eval-after-load 'eww
    (define-key eww-mode-map "f" #'eww-lnum-follow)
    (define-key eww-mode-map "F" #'eww-lnum-universal)))



;6.9. compat

(eval-when-compile
  (el-clone :repo "phikal/compat.el"))

(with-delayed-execution-priority-high
  (message "Install compat...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/compat")))


;.12. File
;.12.1. recentf

(with-delayed-execution
  (message "Install recentf...")
  (autoload-if-found '(recentf-mode) "recentf" nil t)
  (recentf-mode 1)
  (with-eval-after-load 'recentf
    (setq recentf-max-menu-items 10000)
    (setq recentf-max-saved-items 10000)
    (setq recentf-auto-cleanup 'never)
    (setq recentf-save-file  "~/.emacs.d/recentf")
    (setq recentf-auto-save-timer (run-with-idle-timer 30 t 'recentf-save-list))
    (setq recentf-exclude '("recentf" "\\.gpg\\"))))


;.21.3. which-key 例えば C-x して1秒待つと2stroke 候補を表示.
(eval-when-compile
  (el-clone :repo "justbur/emacs-which-key"))

(with-delayed-execution
  (message "Install which-key...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/emacs-which-key"))

  (autoload-if-found '(which-key-mode) "which-key" nil t)

  (which-key-mode))


; markdown-mode
(eval-when-compile
  (el-clone :repo "defunkt/markdown-mode"))

(with-delayed-execution
  (message "Install markdown-mode...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/markdown-mode"))
  (autoload-if-found '(mark-down-mode) "markdown-mode" nil t))

;; (eval-when-compile
;;   (el-clone :repo "tumashu/postframe"))
;; (with-delayed-execution
;;   (message "Install postframe...")
;;   (add-to-list 'load-path (locate-user-emacs-file "el-clone/postframe"))
;;   (autoload-if-found '(postframe) "postframe" nil t))


;.22.12. lsp-bridge
(eval-when-compile
  (el-clone :repo "manateelazycat/lsp-bridge"))

(with-delayed-execution
  (message "Install lsp-bridge...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/lsp-bridge"))

  (autoload-if-found '(lsp-bridge-mode) "lsp-bridge" nil t)

  (with-eval-after-load 'lsp-bridge
    ;; config
    (setq lsp-bridge-c-lsp-server "clangd")
    (setq acm-enable-doc t)
    ;; keybind
    (define-key lsp-bridge-mode-map (kbd "M-.") #'lsp-bridge-find-impl)
    (define-key lsp-bridge-mode-map (kbd "C-c C-r") #'lsp-bridge-find-references)))


;.25. Narrowing
;.25.1. fancy-narrow

(eval-when-compile
  (el-clone :repo "takeokunn/fancy-narrow"))

(with-delayed-execution
  (message "Install fancy-narrow...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/fancy-narrow"))

  (autoload-if-found '(fancy-narrow-mode) "fancy-narrow" nil t)

  ;; (with-eval-after-load 'org
  ;;   (add-hook 'org-mode-hook #'fancy-narrow-mode))

  ;; (with-eval-after-load 'elisp-mode
  ;;   (add-hook 'emacs-lisp-mode-hook #'fancy-narrow-mode))

  ;; (with-eval-after-load 'lisp-mode
  ;;   (add-hook 'lisp-mode-hook #'fancy-narrow-mode))

  ;; (with-eval-after-load 'clojure-mode
  ;;   (add-hook 'clojure-mode-hook #'fancy-narrow-mode))
  )

;.29. Search
;.29.3. consult
(eval-when-compile
  (el-clone :repo "minad/consult"))

(with-delayed-execution
  (message "Install consult...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/consult"))

  (autoload-if-found '(consult-bookmark
                       consult-buffer
                       consult-buffer-other-frame
                       consult-buffer-other-tab
                       consult-buffer-other-window
                       consult-complex-command
                       consult-find
                       consult-flycheck
                       consult-focus-lines
                       consult-git-grep
                       consult-global-mark
                       consult-goto-line
                       consult-grep
                       consult-history
                       consult-isearch-history
                       consult-keep-lines
                       consult-line
                       consult-line-multi
                       consult-locate
                       consult-man
                       consult-mark
                       consult-outline
                       consult-project-buffer
                       consult-register
                       consult-register-load
                       consult-register-store
                       consult-ripgrep
                       consult-yank-pop
                       consult-mode-command

                       ;; other
                       consult-preview-at-point-mode
                       consult-register-window) "consult" nil t)
  (autoload-if-found '(consult-compile-error) "consult-compile" nil t)
  (autoload-if-found '(consult-org-heading consult-org-agenda) "consult-org" nil t)
  (autoload-if-found '(consult-imenu consult-imenu-multi) "consult-imenu" nil t)
  (autoload-if-found '(consult-kmacro) "consult-kmacro" nil t)
  (autoload-if-found '(consult-xref) "consult-xref" nil t)

  ;; keybind
  ;; C-c bindings in `mode-specific-map'
  (global-set-key (kbd "C-c M-x") #'consult-mode-command)
  (global-set-key (kbd "C-c h") #'consult-history)

  ;; C-x bindings in `ctl-x-map'
  (global-set-key (kbd "C-x M-:") #'consult-complex-command)
  (global-set-key (kbd "C-x b")   #'consult-buffer)
  (global-set-key (kbd "C-x 4 b") #'consult-buffer-other-window)
  (global-set-key (kbd "C-x 5 b") #'consult-buffer-other-frame)
  (global-set-key (kbd "C-x C-g") #'consult-ripgrep)

  ;; Other custom bindings
  (global-set-key (kbd "M-y") #'consult-yank-pop)

  ;; M-g bindings in `goto-map'
  (global-set-key (kbd "M-g e") #'consult-compile-error)
  (global-set-key (kbd "M-g f") #'consult-flycheck)
  (global-set-key (kbd "M-g g") #'consult-goto-line)
  (global-set-key (kbd "M-g M-g") #'consult-goto-line)
  (global-set-key (kbd "M-g o") #'consult-outline)
  (global-set-key (kbd "M-g m") #'consult-mark)
  (global-set-key (kbd "M-g k") #'consult-global-mark)
  (global-set-key (kbd "M-g i") #'consult-imenu)
  (global-set-key (kbd "M-g I") #'consult-imenu-multi)

  ;; C-o bindings in `search-map'
  (global-set-key (kbd "C-o") #'(lambda ()
                                  (interactive)
                                  (let ((word (thing-at-point 'symbol 'no-properties)))
                                    (consult-line word))))

  ;; Isearch integration
  (with-eval-after-load 'isearch
    (define-key isearch-mode-map (kbd "M-e") #'consult-isearch-history))

  ;; Minibuffer history
  (with-eval-after-load 'minibuffer
    (define-key minibuffer-local-map (kbd "M-s") #'consult-history)
    (define-key minibuffer-local-map (kbd "M-r") #'consult-history))

  (with-eval-after-load 'simple
    (add-hook 'completion-list-mode #'consult-preview-at-point-mode))

  (with-eval-after-load 'register
    (advice-add #'register-preview :override #'consult-register-window))

  (with-eval-after-load 'xref
    (setq xref-show-xrefs-function #'consult-xref)
    (setq xref-show-definitions-function #'consult-xref)))


;14.4. embark
(eval-when-compile
  (el-clone :repo "oantolin/embark"))

(with-delayed-execution
  (message "Install embark...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/embark"))


(autoload-if-found '(embark-act embark-dwim embark-prefix-help-command) "embark" nil t)

(keymap-global-set "C-." #'embark-act)
(keymap-global-set "M-." #'embark-dwim)
(keymap-global-set "C-h B" #'embark-prefix-help-command)

(with-eval-after-load 'embark
  ;; macros
  (defmacro my/embark-ace-action (fn)
    `(defun ,(intern (concat "my/embark-ace-" (symbol-name fn))) ()
       (interactive)
       (with-demoted-errors "%s"
         (aw-switch-to-window (aw-select nil))
         (call-interactively (symbol-function ',fn)))))

  (defmacro my/embark-split-action (fn split-type)
    `(defun ,(intern (concat "my/embark-"
                             (symbol-name fn)
                             "-"
                             (car (last (split-string
                                         (symbol-name split-type) "-"))))) ()
       (interactive)
       (funcall #',split-type)
       (call-interactively #',fn)))

  (defun my/sudo-find-file (file)
    "Open FILE as root."
    (interactive "FOpen file as root: ")
    (when (file-writable-p file)
      (user-error "File is user writeable, aborting sudo"))
    (find-file (if (file-remote-p file)
                   (concat "/" (file-remote-p file 'method) ":"
                           (file-remote-p file 'user) "@" (file-remote-p file 'host)
                           "|sudo:root@"
                           (file-remote-p file 'host) ":" (file-remote-p file 'localname))
                 (concat "/sudo:root@localhost:" file))))

  ;; config
  (setopt embark-mixed-indicator-delay 0.1)
  (setopt prefix-help-command #'embark-prefix-help-command)

  ;; ace-window
  (define-key embark-file-map     (kbd "o") (my/embark-ace-action find-file))
  (define-key embark-buffer-map   (kbd "o") (my/embark-ace-action switch-to-buffer))
  (define-key embark-bookmark-map (kbd "o") (my/embark-ace-action bookmark-jump))

  ;; split window(2)
  (define-key embark-file-map     (kbd "2") (my/embark-split-action find-file split-window-below))
  (define-key embark-buffer-map   (kbd "2") (my/embark-split-action switch-to-buffer split-window-below))
  (define-key embark-bookmark-map (kbd "2") (my/embark-split-action bookmark-jump split-window-below))

  ;; split window(3)
  (define-key embark-file-map     (kbd "3") (my/embark-split-action find-file split-window-right))
  (define-key embark-buffer-map   (kbd "3") (my/embark-split-action switch-to-buffer split-window-right))
  (define-key embark-bookmark-map (kbd "3") (my/embark-split-action bookmark-jump split-window-right))

  ;; sudo
  (define-key embark-file-map (kbd "S") #'my/sudo-find-file)

  ;; ellama
  (define-key embark-general-map (kbd "T") #'ellama-translate)

  ;; copilot-chat
  (define-key embark-general-map (kbd "E") #'copilot-chat-explain-defun)
  (define-key embark-general-map (kbd "R") #'copilot-chat-review)
  (define-key embark-general-map (kbd "D") #'copilot-chat-doc)
  (define-key embark-general-map (kbd "F") #'copilot-chat-fix)
  (define-key embark-general-map (kbd "O") #'copilot-chat-optimize)
  (define-key embark-general-map (kbd "E") #'copilot-chat-explain-defun)

  ;; hooks
  (add-hook 'embark-collect-mode-hook #'consult-preview-at-point-mode)))



;.29.5. compile-multi

(eval-when-compile
  (el-clone :repo "mohkale/compile-multi"))

(with-delayed-execution
  (message "Install compile-multi...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/compile-multi"))
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/compile-multi/extensions/consult-compile-multi"))
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/compile-multi/extensions/compile-multi-embark"))
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/compile-multi/extensions/compile-multi-all-the-icons"))


  (autoload-if-found '(compile-multi) "compile-multi" nil t)
  (autoload-if-found '(consult-compile-multi-mode) "consult-compile-multi" nil t)
  (autoload-if-found '(compile-multi-embark-mode) "compile-multi-embark" nil t)

  (global-set-key (kbd "C-x m") #'compile-multi)

  (with-eval-after-load 'consult
    (consult-compile-multi-mode))

  (with-eval-after-load 'embark
    (compile-multi-embark-mode)))

;.29.6. vertico

(eval-when-compile
  (el-clone :repo "minad/vertico"))

(with-delayed-execution
  (message "Install vertico...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/vertico"))
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/vertico/extensions"))
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/vertico-directory"))

  (autoload-if-found '(vertico-mode) "vertico" nil t)
  (autoload-if-found '(vertico-directory-tidy
                       vertico-directory-enter
                       vertico-directory-up
                       vertico-directory-delete-char
                       vertico-directory-delete-word) "vertico-directory" nil t)
  (autoload-if-found '(vertico-flat-mode) "vertico-flat" nil t)


  (defvar +vertico-current-arrow t)
  
  (vertico-mode)

  (with-eval-after-load 'rfn-eshadow
    (add-hook 'rfn-eshadow-update-overlay #'vertico-directory-tidy))

  (with-eval-after-load 'vertico
    (setq vertico-count 12)
    (setq vertico-cycle t))
    (setq vertico-resize t)
    (define-key vertico-map (kbd "C-l") #'vertico-directory-up)
  )


;.29.7. marginalia

(eval-when-compile
  (el-clone :repo "minad/marginalia"))

(with-delayed-execution
  (message "Install marginalia...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/marginalia"))
  (autoload-if-found '(marginalia-mode) "marginalia" nil t)

  (marginalia-mode)

  (with-eval-after-load 'minibuffer
    (define-key minibuffer-local-map (kbd "M-A") #'marginalia-cycle)))

;.29.8. orderless

(eval-when-compile
  (el-clone :repo "oantolin/orderless"))

(with-delayed-execution
  (message "Install orderless...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/orderless"))

  (autoload-if-found '(orderless-all-completions
                       orderless-try-completion) "orderless" nil t)

  (with-eval-after-load 'minibuffer
    (setq completion-styles '(orderless basic))
    ;; (setq completion-category-overrides '((file (styles basic partial-completion))))

    (add-to-list 'completion-styles-alist '(orderless orderless-try-completion orderless-all-completions
                                                      "Completion of multiple components, in any order."))))


;; affe
(eval-when-compile
  (el-clone :repo "minad/affe"))

(with-delayed-execution
  (message "Install affe...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/affe")))

(autoload-if-found '(affe-grep) "affe" nil t)

(with-eval-after-load 'affe
  ;; config
  (setopt affe-highlight-function 'orderless-highlight-matches)
  (setopt affe-find-command "fd --color=never --full-path")
  (setopt affe-regexp-function 'orderless-pattern-compiler))


;;; MEMO mail setting. TODO yahooのSMS認証を解除するか対応
;; ;; mail mew
;; (add-to-list 'load-path (locate-user-emacs-file "el-clone/mew/elisp"))
;; (autoload 'mew "mew" nil t)
;; (autoload 'mew-send "mew" nil t)
;; (setq mew-icon-directory (expand-file-name "~./.emacs.d/el-clone/mew/etc"))
;; (add-to-list 'image-load-path (expand-file-name "~./.emacs.d/el-clone/mew/etc"))
;; ;;; パスワードを表示させないための設定
;; (add-hook 'comint-output-filter-functions 'comint-watch-for-password-prompt)
;; ;;Account setting
;; (setq mew-name "ronaldobraziljp") ;; (user-full-name)
;; (setq mew-user "ronaldobraziljp") ;; (user-login-name)
;; (setq mew-mail-domain "yahoo.co.jp")
;; ;;IMAP setting
;; (setq mew-proto "%")
;; (setq mew-imap-user "ronaldobraziljp@yahoo.co.jp")
;; (setq mew-imap-server "imap.mail.yahoo.co.jp")
;; (setq mew-imap-auth t)
;; (setq mew-imap-ssl t)
;; (setq mew-imap-ssl-port "993")
;; ;;SMTP setting
;; (setq mew-smtp-user "ronaldobraziljp@yahoo.co.jp")
;; (setq mew-smtp-server "smtp.mail.yahoo.co.jp")
;; (setq mew-smtp-auth t)
;; (setq mew-ssl-verify-level 0)
;; (setq mew-smtp-port "submission") ;; The default is "smtp" (25)
;; (setq mew-smtp-ssl t)
;; (setq mew-smtp-ssl-port mew-smtp-port) ;; The default is 465




;.30. Shell
;.30.1. exec-path-from-shell

(eval-when-compile
  (el-clone :repo "purcell/exec-path-from-shell"))

(with-delayed-execution-priority-high
  (message "Install exec-path-from-shell...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/exec-path-from-shell"))

  (autoload-if-found '(exec-path-from-shell-initialize) "exec-path-from-shell")
  (exec-path-from-shell-initialize)

  (with-eval-after-load 'exec-path-from-shell
    (setq exec-path-from-shell-variables '("PATH"
                                           "GEM_HOME"
                                           "GOROOT"
                                           "GOPATH"
                                           "LSP_USE_PLISTS"
                                           "TERM"
                                           "SSH_AUTH_SOCK"
                                           "NATIVE_FULL_AOT"
                                           "GPG_TTY"))))

;.31. Snippet
;.31.1. yasnippet

(eval-when-compile
  (el-clone :repo "joaotavora/yasnippet"))

(with-delayed-execution
  (message "Install yasnippet...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/yasnippet"))

  (autoload-if-found '(yas-global-mode) "yasnippet" nil t)

  (yas-global-mode 1))

;.31.2. consult-yasnippet

(eval-when-compile
 (el-clone :repo "mohkale/consult-yasnippet"))

(with-delayed-execution
  (message "Install consult-yasnippet...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/consult-yasnippet"))

  (autoload-if-found '(consult-yasnippet) "consult-yasnippet" nil t)

  (global-set-key (kbd "C-c y") #'consult-yasnippet)
  (global-set-key (kbd "C-c C-y") #'consult-yasnippet))

;.31.3. yasnippet-org

(eval-when-compile
  (el-clone :repo "takeokunn/yasnippet-org"))

(with-delayed-execution
  (message "Install yasnippet-org...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/yasnippet-org"))

  (autoload-if-found '(yasnippet-org) "yasnippet-org" nil t)

  (with-eval-after-load 'yasnippet-org
    (setq yasnippet-org-verbose t)))


;.35. Tab
;.35.1. tab-bar

(with-delayed-execution
  (message "Install tab-bar...")
  (autoload-if-found '(tab-bar-mode
                       tab-bar-history-mode
                       tab-previous
                       tab-next) "tab-bar" nil t)

  (tab-bar-history-mode)

  (global-set-key (kbd "C-x C-t") tab-prefix-map)
  (global-set-key (kbd "M-[") #'tab-previous)
  (global-set-key (kbd "M-]") #'tab-next)

  (with-eval-after-load 'tab-bar
    (setq tab-bar-close-button-show nil)
    (setq tab-bar-close-last-tab-choice nil)
    (setq tab-bar-close-tab-select 'left)
    (setq tab-bar-history-mode nil)
    (setq tab-bar-new-tab-choice "*scratch*")
    (setq tab-bar-new-button-show nil)
    (setq tab-bar-tab-name-truncated-max 12)
    (setq tab-bar-separator " | "))

  (defun my/tab-bar-rename-tab ()
    (interactive)
    (let ((proj-name (projectile-project-name)))
      (tab-bar-rename-tab proj-name)))

  ;; rename tab-bar with projectile
  (define-key tab-prefix-map (kbd "r") #'my/tab-bar-rename-tab)

  ;; close neotree when tab bar action
  (advice-add 'tab-new :before #'(lambda (&rest _) (neotree-hide)))
  (advice-add 'tab-next :before #'(lambda (&rest _) (neotree-hide)))
  (advice-add 'tab-bar-switch-to-tab :before #'(lambda (&rest _) (neotree-hide)))

  ;; hook
  (add-hook 'tab-bar-mode-hook #'(lambda () (display-line-numbers-mode -1))))

;.37. Theme
;.37.1. all-the-icons

(eval-when-compile
  (el-clone :repo "domtronn/all-the-icons.el"))

(with-delayed-execution-priority-high
  (message "Install all-the-icons...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/all-the-icons")))

;.37.2. all-the-icons-dired

(eval-when-compile
  (el-clone :repo "jtbm37/all-the-icons-dired"))

(with-delayed-execution
  (message "Install all-the-icons-dired...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/all-the-icons-dired"))

  (autoload-if-found '(all-the-icons-dired-mode) "all-the-icons-dired")

  (with-eval-after-load 'dired
    (add-hook 'dired-mode-hook #'all-the-icons-dired-mode)))

;.37.3. all-the-icons-completion

(eval-when-compile
  (el-clone :repo "iyefrat/all-the-icons-completion"))

(with-delayed-execution
  (message "Install all-the-icons-completion...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/all-the-icons-completion"))

  (autoload-if-found '(all-the-icons-completion-marginalia-setup) "all-the-icons-completion" nil t)

  (all-the-icons-completion-marginalia-setup))

;.37.4. dashboard
;; (eval-when-compile
;;   (el-clone :repo "emacs-dashboard/emacs-dashboard"))

;; (with-delayed-execution
;;   (message "Install dashboard...")
;;   (add-to-list 'load-path (locate-user-emacs-file "el-clone/emacs-dashboard"))

;;   (autoload-if-found '(dashboard-refresh-buffer) "dashboard" nil t)

;;   (with-eval-after-load 'dashboard
;;     (setq dashboard-startup-banner 'logo)
;;     (setq dashboard-set-file-icons t)
;;     (setq dashboard-startup-banner 4)
;;     (setq dashboard-items '((recents . 10)
;;                             (projects . 5)
;;                             (agenda . 5)))
;;     )
;;   )

(require 'dashboard)
     (setq dashboard-startup-banner 'logo)
     (setq dashboard-set-file-icons t)
     (setq dashboard-startup-banner 4)
     (setq dashboard-items '((recents . 10)
                             (projects . 5)
                             (agenda . 5)))
(dashboard-setup-startup-hook)



;.37.5. dimmer
(eval-when-compile
  (el-clone :repo "gonewest818/dimmer.el"))

(with-eval-after-load 'dimmer
  (message "Install dimmer...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/dimmer"))

  (autoload-if-found '(dimmer-configure-which-key
                       dimmer-configure-org
                       dimmer-mode)
                     "dimmer" nil t)

  (dimmer-configure-which-key)
  (dimmer-configure-org)
  (dimmer-mode t))


;.37.12. nyan-mode

(eval-when-compile
  (el-clone :repo "TeMPOraL/nyan-mode"))

(with-delayed-execution-priority-high
  (message "Install nyan-mode...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/nyan-mode"))
  (autoload-if-found '(nyan-mode) "nyan-mode" nil t)
  (nyan-mode)
  (with-eval-after-load 'nyan-mode
    (setq nyan-cat-face-number 5)
    (setq nyan-animation-frame-interval 1)
    (setq nyan-bar-length 18)
    (setq nyan-animate-nyancat t)))



;.41.12. restclient
(eval-when-compile
  (el-clone :repo "pashky/restclient.el"))

(with-delayed-execution
  (message "Install restclient...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/restclient"))

  (autoload-if-found '(restclient-mode) "restclient" nil t))

;.41.13. smartparens
(eval-when-compile
  (el-clone :repo "Fuco1/smartparens"))
(with-delayed-execution
  (message "Install smartparens...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/smartparens"))
  (with-eval-after-load 'smartparens))

; puni
(eval-when-compile
  (el-clone :repo "AmaiKinono/puni"))
(with-delayed-execution
  (message "Install puni...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/puni"))
  (autoload-if-found '(puni-mode) "puni" nil t)
  (dolist (hook '(lisp-interaction-mode-hook minibuffer-mode-hook prog-mode-hook org-mode-hook lisp-mode-hook emacs-lisp-mode-hook c-mode-hook c++-mode-hook sgml-mode-hook nxml-mode-hook tex-mode-hook eval-expression-minibuffer-setup-hook))
    (global-set-key (kbd "<M-BS>") 'puni-backward-kill-word )
    (global-set-key (kbd "C-@")    'puni-expand-region )
    (global-set-key (kbd "C-!")  'puni-mark-sexp-at-point )
    (global-set-key (kbd "C-#")  'puni-mark-list-around-point )
    (global-set-key (kbd "C-$")  'puni-mark-sexp-around-point )
    (global-set-key (kbd "C-d")  'puni-forward-delete-char)
    (global-set-key (kbd "<DEL>")'puni-backward-delete-char )
    (global-set-key (kbd "M-d")  'puni-forward-kill-word )
    (global-set-key (kbd "M-DEL")  'puni-backword-kill-word )
    (global-set-key (kbd "C-k")  'puni-kill-line)
    (global-set-key (kbd "C-S-k")  'puni-backward-kill-line)
    (add-hook hook #'puni-mode)))


; visual regexp 置換
(eval-when-compile
  (el-clone :repo "benma/visual-regexp.el"))
(with-delayed-execution
  (message "Install visual-regexp...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/visual-regexp"))  
  (autoload-if-found '(visual-regexp) "visual-regexp" nil t))
  
  


;.41.14. smart-jump
(eval-when-compile
  (el-clone :repo "jojojames/smart-jump"))
(with-delayed-execution
  (message "Install smart-jump...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/smart-jump"))
  (with-eval-after-load 'smart-jump))


;.42.1. ace-window
(eval-when-compile
  (el-clone :repo "abo-abo/ace-window"))

(with-delayed-execution
  (message "Install ace-window...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/ace-window"))

  (autoload-if-found '(ace-window) "ace-window" nil t)

  (global-set-key (kbd "C-x o") #'ace-window)

  (with-eval-after-load 'ace-window
    (setq aw-dispatch-always t)
    (setq aw-scope 'frame)
    (setq aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l))
    (setq aw-minibuffer-flag t)))




;1.12. mistty inside shell
(eval-when-compile
  (el-clone :repo "szermatt/mistty"))
(with-delayed-execution
  (message "Install mistty...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/mistty"))
  (autoload-if-found '(mistty) "mistty" nil t))


; ox-qmd org-mode to qiita markdown export C-c C-e
(eval-when-compile
  (el-clone :repo "0x60df/ox-qmd"))
(with-delayed-execution
  (message "Install ox-qmd...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/ox-qmd"))
  (autoload-if-found '(org-qmd-export-to-markdown org-qmd-convert-region-to-md) "ox-qmd" nil t))

;; ; minions : minor-mode show few word.
;; (eval-when-compile
;;   (el-clone :repo "tarsius/minions"))
;; (with-delayed-execution
;;   (message "Install minions...")
;;   (add-to-list 'load-path (locate-user-emacs-file "el-clone/minions"))
;;   ;(add-hook 'org-mode-hook #'minions-mode)
;;   ;(add-hook 'org-mode-hook #'(lambda ()
;;   ;                             (minions-mode)
;;   ;                             (setq minions-mode-line-lighter "[+]")))
;;   ;(setq minions-prominent-modes '(flymake-mode))
;;   )


; org
(with-eval-after-load 'org
  ;; タグリスト
  (setq org-tag-alist '(("home" . ?h) ("office" . ?o) ("meeting" . ?m)))
  ;; DONE etc.faces.
  (setq org-todo-keyword-faces
      '(
      ("TODO" . org-warning)
      ("WAIT" . "PaleGreen")
      ("SOMEDAY" . "OliveDrab")
      ("DONE" . "LightSlateGray")))
      
; https://sachachua.com/blog/2012/12/emacs-strike-through-headlines-for-done-tasks-in-org/
(setq org-fontify-done-headline t)
(custom-set-faces
 '(org-done ((t (:foreground "PaleGreen"   
                 :weight normal
                 :strike-through t))))
 '(org-headline-done 
            ((((class color) (min-colors 16) (background dark)) 
               (:foreground "LightSalmon" :strike-through t)))))

  (setq org-return-follows-link t)  ; Returnキーでリンク先を開く
  (setq org-mouse-1-follows-link t) ; マウスクリックでリンク先を開く
  (setq org-startup-indented t)    ;; 見出しをインデント
  (setq org-indent-mode-turns-on-hiding-stars nil)  ;; 見出しをインデントした時にアスタリスクが減るのを防ぐ
  (setq org-indent-indentation-per-level 2)  ;; インデントの幅を設定
  (setq org-startup-folded 'content)  ;; 見出しの初期状態（見出しだけ表示）

  ; アンダースコアを入力しても下付き文字にならないようにする
  (setq org-use-sub-superscripts '{}
      org-export-with-sub-superscripts nil)

  ;; keybind
  (define-key org-mode-map (kbd "C-c ,") #'org-insert-structure-template)
  (define-key org-mode-map (kbd "C-c C-,") #'org-insert-structure-template)

  ;; directory
  (setq org-directory "~/Dropbox")

  ;; enable speed commands
  (setq org-use-speed-commands t)

  ;; todo
  (setq org-todo-keywords '((sequence "TODO(t)" "SOMEDAY(s)" "WAIT(w)" "|" "DONE(d)")))

  ;; startup
  (setq org-startup-folded 'show3levels)
  (setq org-startup-truncated nil)
  (setq org-src-window-setup 'current-window)

  ;; archive
  (advice-add 'org-archive-subtree :before #'(lambda (&rest _) (remove-hook 'find-file-hooks #'view-mode)))
  (advice-add 'org-archive-subtree :after #'(lambda (&rest _) (add-hook 'find-file-hooks #'view-mode)))

  (defvar my/org-agenda-files `(,(concat org-directory "/AI.org")
                                ,(concat org-directory "/personal.org")
                                ,(concat org-directory "/notes.org")))

  (setq org-agenda-files my/org-agenda-files)
  (setq org-archive-location `,(format (expand-file-name "archive/%s/%s.org::* Archived Tasks" org-directory)
                                       (format-time-string "%Y" (current-time))
                                       (format-time-string "%Y-%m-%d" (current-time))))

  ;; log
  (setq org-log-into-drawer t)
  (setq org-log-done 'time)

  (defun my/update-org-agenda-files ()
    (interactive)
    (setq org-agenda-files my/org-agenda-files)))



;2.1.2. org-clock

(with-eval-after-load 'org-clock
  (add-hook 'org-mode-hook #'org-clock-load)
  (add-hook 'kill-emacs-hook #'org-clock-save)

  (setq org-clock-out-remove-zero-time-clocks t)
  (setq org-clock-clocked-in-display 'mode-line))

;2.1.3. org-list

(with-eval-after-load 'org-list
  (setq org-list-allow-alphabetical t))

;2.1.4. org-keys

(with-eval-after-load 'org-keys
  (setq org-use-extra-keys t)
  (setq org-use-speed-commands t)

  (add-to-list 'org-speed-commands '("d" org-todo "DONE"))
  (add-to-list 'org-speed-commands '("j" call-interactively #'consult-org-heading)))

;2.1.5. org-capture

(with-delayed-execution
  (autoload-if-found '(org-capture) "org-capture" nil t)
  (global-set-key (kbd "C-c c") #'org-capture)

  (advice-add 'org-capture :before #'(lambda (&rest _) (remove-hook 'find-file-hooks #'view-mode)))
  (advice-add 'org-capture :after #'(lambda (&rest _) (add-hook 'find-file-hooks #'view-mode)))

  (with-eval-after-load 'org-capture
    (setq org-capture-use-agenda-date t)
    (setq org-capture-bookmark nil)
    (setq org-capture-templates `(("t" "Todo" entry (file ,(expand-file-name "todo.org" org-directory))
                                   "* %?")
                                  ("m" "Memo" entry (file ,(expand-file-name "memo.org" org-directory))
                                   "* %?")
                                  ("j" "Journal" entry (file+olp+datetree ,(expand-file-name "journal.org" org-directory))
                                   "* %U\n%?\n%i\n")))))

;2.1.6. org-duration

(with-eval-after-load 'org-duration
 (setq org-duration-format (quote h:mm)))

;2.1.7. org-id

(with-delayed-execution
  (message "Install org-id...")

  (autoload-if-found '(org-id-store-link) "org-id" nil t)

  (with-eval-after-load 'org-id
    (setq org-id-locations-file (expand-file-name ".org-id-locations" org-directory))
    (setq org-id-extra-files (append org-agenda-text-search-extra-files))))


;2.1.10. org-journal

(eval-when-compile
  (el-clone :repo "bastibe/org-journal"))

(with-delayed-execution
  (message "Install org-journal...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/org-journal"))

  (with-eval-after-load 'org-journal
;    (setq org-journal-dir (expand-file-name "journal" org-directory))
    (setq org-journal-start-on-weekday 7)
    (setq org-journal-prefix-key "C-c j")

 (setq org-journal-dir "~/Dropbox/journal")
 (setq org-journal-date-format "%Y-%m-%d, %A")
 (setq org-journal-time-format "%R\n\n")
 (setq org-journal-file-format "%Y%m%d.org")
 ;;(setq org-journal-file-type 'monthly)
 (setq org-journal-find-file 'find-file)
 (setq org-journal-file-header 'org-journal-file-header-func)))

(defun my/org-journal-open ()
(interactive)
(load "~/.emacs.d/el-clone/org-journal/org-journal.el")
 (setq org-journal-dir "~/Dropbox/journal")
 (setq org-journal-date-format "%Y-%m-%d, %A")
 (setq org-journal-time-format "%R\n\n")
 (setq org-journal-file-format "%Y%m%d.org")
 ;;(setq org-journal-file-type 'monthly)
 (setq org-journal-find-file 'find-file)
 (setq org-journal-file-header 'org-journal-file-header-func)
(org-journal-new-entry t))
(global-set-key (kbd "C-c j") 'my/org-journal-open)


;2.1.12. org-pomodoro

(eval-when-compile
  (el-clone :repo "marcinkoziej/org-pomodoro"))

(with-delayed-execution
  (message "Install org-pomodoro...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/org-pomodoro"))

  (autoload-if-found '(org-pomodoro) "org-pomodoro" nil t))


;2.2.1. org-faces

(with-eval-after-load 'org-faces
  (setq org-link '(t (:foreground "#ebe087" :underline t))))

;2.2.2. org-superstar

(eval-when-compile
  (el-clone :repo "integral-dw/org-superstar-mode"))

(with-delayed-execution
  (message "Install org-superstar...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/org-superstar-mode"))

  (autoload-if-found '(org-superstar-mode) "org-superstar")

  (with-eval-after-load 'org
    (add-hook 'org-mode-hook #'org-superstar-mode))

  (with-eval-after-load 'org-superstar
    (setq org-superstar-headline-bullets-list '("◉" "○" "✸" "✿"))
    (setq org-superstar-leading-bullet " ")))


;2.5.1. org-link

(with-delayed-execution
  (message "Install ol...")

  (autoload-if-found '(org-store-link) "ol" nil t)

  (global-set-key (kbd "C-c l") #'org-store-link)

  (with-eval-after-load 'ol
    (setq org-link-file-path-type 'relative)))


;; link to clipboard org link format
(defun to-clipboard (x)
      "与えられた文字列をクリップボードにコピーします"
      (when x
        (with-temp-buffer
          (insert x)
          (clipboard-kill-region (point-min) (point-max)))
        (message x)))

(defun file-full-path ()
      "今開いているファイルの絶対パス::行数を返します"
      (if (equal major-mode 'dired-mode)
          default-directory
        (concat (buffer-file-name) "::" (number-to-string (line-number-at-pos)))))
  
(defun file-full-path-org-link-to-clipboard ()
      "今開いているファイルの org link をクリップボードにコピーします"
      (interactive)
      (require 'which-func) ; require は最初一回だけloadするのでここで大丈夫.
      (to-clipboard (concat "[[" (file-full-path) "][" (file-name-nondirectory buffer-file-name) " "
       (string-replace "%" "%%"
         (or
           (gethash
             (selected-window)
              which-func-table)
              which-func-unknown))
       "]]")))


;2.5.2. org-link-beautify

(eval-when-compile
  (el-clone :repo "emacsmirror/org-link-beautify"))

(with-delayed-execution
  (message "Install org-link-beautify...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/org-link-beautify"))

  (autoload-if-found '(org-link-beautify-mode) "org-link-beautify" nil t)

  ;; (with-eval-after-load 'org
  ;;   (add-hook 'org-mode-hook #'org-link-beautify-mode))
  )


;2.6.1. Basic

(with-delayed-execution
  (message "Install org-agenda...")
  (autoload-if-found '(org-agenda) "org-agenda" nil t)

  (global-set-key (kbd "C-c a") #'org-agenda)

  (with-eval-after-load 'org-agenda
    (setq org-agenda-span 'day)
    (setq org-agenda-start-on-weekday 1)
    (setq org-agenda-todo-ignore-with-date t)))

;2.6.2. org-super-agenda

(eval-when-compile
  (el-clone :repo "alphapapa/org-super-agenda"))

(with-delayed-execution
  (message "Install org-super-agenda...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/org-super-agenda"))

  (autoload-if-found '(org-super-agenda-mode) "org-super-agenda" nil t)

  (org-super-agenda-mode)

  (with-eval-after-load 'org-super-agenda
    (setq org-super-agenda-groups '((:log t)
                                    (:auto-group t)
                                    (:name "Today List..." :scheduled today)
                                    (:name "Due Today List..." :deadline today)
                                    (:name "Overdue List..." :deadline past)
                                    (:name "Due Soon List" :deadline future)
                                    (:name "TODO List..." :todo "TODO")
                                    (:name "WAIT List..." :todo "WAIT")
                                    (:name "DONE List..." :todo "DONE")
                                    (:name "SOMEDAY List..." :todo "SOMEDAY")))))


;2.8.1. basic

(with-delayed-execution
  (message "Install ob-babel...")
  (autoload-if-found '(org-babel-do-load-languages) "org" nil t)

  (with-eval-after-load 'ob-core
    (setq org-confirm-babel-evaluate nil)

    (add-to-list 'org-babel-default-header-args '(:results . "output")))

  (with-eval-after-load 'ob-eval
    (advice-add #'org-babel-eval-error-notify
                :around #'(lambda (old-func &rest args)
                            (when (not (string= (nth 1 args)
                                                "mysql: [Warning] Using a password on the command line interface can be insecure.\n"))
                              (apply old-func args)))))


  ;; plantuml.jarへのパスを設定
  (setq org-plantuml-jar-path "~/.emacs.d/lib/plantuml.jar")

  (org-babel-do-load-languages 'org-babel-load-languages
                               '((awk . t)
                                 (C . t)
                                 (R . t)
                                 ;(clojure . t)
                                 (emacs-lisp . t)
                                 (haskell . t)
                                 (java . t)
                                 (js . t)
                                 (lisp . t)
                                 (makefile . t)
                                 ;(perl . t)
                                 (plantuml . t)
                                 (python . t)
                                 (ruby . t)
                                 ;(scheme . t)
                                 ;(shell . t)
                                 (sql . t)
                                 (shell . t))))


; highlight-symbol
(eval-when-compile
  (el-clone :repo "nschum/highlight-symbol.el"))
(with-delayed-execution
  (message "Install highlight-symbol...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/highlight-symbol"))

  (autoload-if-found '(highlight-symbol-mode) "highlight-symbol" nil t)
  ;;; 1秒後自動ハイライトされるようになる
  (setq highlight-symbol-idle-delay 1.0)
  ;;; 自動ハイライトをしたいならば
  (add-hook 'prog-mode-hook 'highlight-symbol-mode))

; golden ratio mode 
(eval-when-compile
  (el-clone :repo "roman/golden-ratio.el"))
(with-delayed-execution
  (message "Install golden-ratio...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/golden-ratio"))
  (autoload-if-found '(golden-ratio-mode) "golden-ratio" nil t)
  (setq golden-ratio-auto-scale t)
  (golden-ratio-mode t)
  )

; vundo undo / redo vizual M-x vundo f b n p key q:quit
(eval-when-compile
  (el-clone :repo "casouri/vundo"))
(with-delayed-execution
  (message "Install vundo...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/vundo"))
  (autoload-if-found '(vundo) "vundo" nil t)
  )


; find file in project fdfind
(eval-when-compile
  (el-clone :repo "redguardtoo/find-file-in-project"))
(with-delayed-execution
  (message "Install redguardtoo/find-file-in-project...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/find-file-in-project"))
  (autoload-if-found '(find-file-in-project) "find-file-in-project" nil t)
  (setq ffip-project-root "~/")
  (setq ffip-use-rust-fd t))


; cmigemo
(eval-when-compile
  (el-clone :repo "emacs-jp/migemo"))
(with-delayed-execution
  (message "Install emacs-jp/migemo...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/migemo"))
  (autoload-if-found '(migemo) "migemo" nil t)
  (setq migemo-options '("-q" "--emacs"))
  (setq migemo-user-dictionary nil)
  (setq migemo-regex-dictionary nil)
  (setq migemo-coding-system 'utf-8-unix)
  (setq migemo-command "cmigemo")
  (setq migemo-dictionary "/usr/share/cmigemo/utf-8/migemo-dict")
  (setq migemo-use-pattern-alist t)
  (setq migemo-use-frequent-pattern-alist t)
  (load-library "migemo")
  (migemo-init))

;; browse-kill-ring
(eval-when-compile
  (el-clone :repo "browse-kill-ring/browse-kill-ring"))
(with-delayed-execution
  (message "Install browse-kill-ring...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/browse-kill-ring"))
  (autoload-if-found '(browse-kill-ring) "browse-kill-ring" nil t)
  )

; easy-kill Kill & Mark Things Easily in Emacs
;; M-w w: save word at point
;; M-w s: save sexp at point
;; M-w l: save list at point (enclosing sexp)
;; M-w d: save defun at point
;; M-w D: save current defun name
;; M-w f: save file at point
;; ;; M-w b: save buffer-file-name
(eval-when-compile
  (el-clone :repo "leoliu/easy-kill"))
(with-delayed-execution
  (message "Install leoliu/easy-kill...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/easy-kill"))
  (autoload-if-found '(easy-kill) "easy-kill" nil t)
  (global-set-key [remap kill-ring-save] 'easy-kill))

(defun org-show-one-levels ()
  (interactive)
  (org-content 1))

(defun org-show-two-levels ()
  (interactive)
  (org-content 2))

(defun lines-comment ()
  (interactive)
  (save-excursion
    (if (region-active-p)
      (progn 
	    (setq original_begin (region-beginning))
	    (setq original_end (region-end))
	    (goto-char (region-beginning))
	    (beginning-of-line)
	    (set-mark (point))
	    (goto-char original_end)
	    (end-of-line)
	    (comment-or-uncomment-region (region-beginning) (region-end))
      )
      (beginning-of-line)
      (set-mark (point))
      (end-of-line)
      (comment-or-uncomment-region (region-beginning) (region-end))
)))


; dump-jump
(eval-when-compile
  (el-clone :repo "jacktasia/dumb-jump"))
(with-delayed-execution
  (message "Install dumb-jump...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/dumb-jump"))
  (autoload-if-found '(dumb-jump-mode) "dumb-jump" nil t)
  (global-set-key (kbd "C-c C-g") 'dumb-jump-go)
  (global-set-key (kbd "C-c C-p") 'dumb-jump-back)
  (global-set-key (kbd "C-c C-q") 'dumb-jump-quick-look)
  (add-hook 'xref-backend-functions #'dumb-jump-xref-activate) ;; xref使うらしい
  (setq dumb-jump-force-searcher 'rg) ;; default git grepが使われてエラー
  (setq dumb-jump-prefer-searcher 'rg) ;; rgコマンドを優先的に利用する
  (setq dumb-jump-default-project "")  ;; $HOME以下が検索対象になるのを回避
  (setq dumb-jump-disable-obsolete-warnings t) ;; レガシーコマンドの警告非表示
  (add-hook 'prog-mode-hook 'dumb-jump-mode)
  (add-hook 'emacs-lisp-mode-hook 'dumb-jump-mode)
  )


;; cursor demonstrate (like beacon)
(eval-when-compile
  (el-clone :repo "protesilaos/pulsar"))

(with-delayed-execution
  (message "Install pulsar...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/pulsar"))
  (autoload-if-found '(pulsar-global-mode) "pulsar" nil t)
  (pulsar-global-mode +1))


; goggles pulse paste region
(eval-when-compile
  (el-clone :repo "minad/goggles"))

(with-delayed-execution
  (message "Install goggles...")
  (add-to-list 'load-path (locate-user-emacs-file "el-clone/goggles"))

  (autoload-if-found '(goggles-mode) "goggles" nil t)
  
  ;; 色を薄くする回数、1で即消える
  (custom-set-variables '(goggles-pulse-iterations 2))
  ;; 色を薄くする1回ごとの秒数
  (custom-set-variables '(goggles-pulse-delay 0.1))
  
  (custom-set-faces
   ;'(goggles-added ((t (:background "#382c39"))))
   '(goggles-added   ((t (:background "#010101"))))
   '(goggles-changed ((t (:background "#c9ba99"))))
   '(goggles-removed ((t (:background "#fabfbb")))))
  (add-hook 'prog-mode-hook 'goggles-mode)
   ; (add-hook 'org-mode-hook 'goggles-mode)
  )



(global-set-key (kbd "C-/") 'lines-comment)

(global-set-key (kbd "<f1>") 'highlight-symbol-prev )
(global-set-key (kbd "<f2>") 'highlight-symbol )
(global-set-key (kbd "<f3>") 'highlight-symbol-next )
(global-set-key (kbd "<f4>") 'consult-buffer)
(global-set-key (kbd "<f5>") 'find-file-in-project)
(global-set-key (kbd "<f6>") 'org-agenda)
(global-set-key (kbd "<f7>") 'revert-buffer)
(global-set-key (kbd "<f8>") 'org-show-two-levels)
(global-set-key (kbd "<S-f8>") 'org-show-one-levels)
(global-set-key (kbd "<f9>") 'file-full-path-org-link-to-clipboard)
(global-set-key (kbd "<f10>") 'calculator)
(global-set-key (kbd "<S-f7>") 'other-window)
(global-set-key (kbd "A-y") 'browse-kill-ring )

; adust U F17
;(global-set-key (kbd "<XF86Launch8>") 'mode-line-other-buffer)
(global-set-key (kbd "<XF86Launch8>") 'other-window)


(global-set-key (kbd "<S-f2>") 'delete-window )
(global-set-key (kbd "<S-f3>") 'split-window-horizontally)

; visual 置換
(define-key global-map (kbd "C-c r") 'vr/replace)
(define-key global-map (kbd "C-c q") 'vr/query-replace)


(global-set-key (kbd "C-s") #'consult-line) ;; バッファ検索
(global-set-key (kbd "C-S-s") #'consult-line-multi) ;; 複数バッファ串刺し検索
(global-set-key (kbd "C-M-s") #'consult-line-migemo) ;; migemo search

(global-set-key (kbd "C-x C-p") #'switch-to-prev-buffer)
(global-set-key (kbd "C-x C-n") #'switch-to-next-buffer)



;; カーソル下のシンボルを拾ってconsult-line発動
(defun consult-line-symbol-at-point (&optional at-point)
  "Consult-line uses things-at-point if set C-u prefix."
  (interactive "P")
  (if at-point
      (consult-line (thing-at-point 'symbol))
    (consult-line)))

;; consult-buffer の live preview でシンタックスハイライトさせない
;; 画像プレビューには向いていない
(setq consult-preview-partial-size 0)

;; 0に設定すれば画像やPDFプレビューさせない（バッファを開いていない場合）
(setq consult-preview-partial-chunk 102400)

;; ローマ字入力でconsult-lineを発動する
(defun consult-line-migemo ()
  (interactive)
  (let ((input (read-string "Input: " nil)))
    (consult-line (migemo-get-pattern input))))
;; migemo検索中からでもconsult-line発動
(defun consult-line-migemo-isearch ()
  (interactive)
  (consult-line (migemo-get-pattern isearch-string)))
(define-key isearch-mode-map (kbd "C-o") #'consult-line-migemo-isearch)


(setq x-select-enable-clipboard t)
(setq split-height-threshold nil)

;6.1. byte-compileする
;; (eval-when-compile
;;   (el-clone-byte-compile))

;6.2. Magic File Name を有効にする
(setq file-name-handler-alist my/saved-file-name-handler-alist)

; https://qiita.com/nobuyuki86/items/122e85b470b361ded0b4
; gc https://emacsconf.org/2023/talks/gc/
(setq gc-cons-percentage 0.2
      gc-cons-threshold (* 128 1024 1024))
(add-hook 'focus-out-hook #'garbage-collect)
(setq process-adaptive-read-buffering t)
(setq blink-matching-paren nil)
(setq auto-mode-case-fold nil)
(setq-default bidi-display-reordering 'left-to-right)
(setq bidi-inhibit-bpa t)
(setq-default cursor-in-non-selected-windows nil)
(setq highlight-nonselected-windows nil)
(setq fast-but-imprecise-scrolling t)
(setq ffap-machine-p-known 'reject)
(setq idle-update-delay 1.0)
(setq redisplay-skip-fontification-on-input t)



; https://apribase.net/2024/07/23/emacs-optimize/
(setq frame-inhibit-implied-resize t)

;; OS判定用関数
(defconst IS-MAC (eq system-type 'darwin))
(defconst IS-LINUX (memq system-type '(gnu gnu/linux gnu/kfreebsd berkeley-unix)))
(defconst IS-WINDOWS (memq system-type '(cygwin windows-nt ms-dos)))


(when IS-WINDOWS
  (setq w32-get-true-file-attributes nil
        w32-pipe-read-delay 0
        w32-pipe-buffer-size (* 64 1024)))
(when IS-WINDOWS
  (setq w32-use-native-image-API t))
(unless IS-MAC
  (setq command-line-ns-option-alist nil)

;.12. [mac] clipboardに入るようにする
  (with-delayed-execution
    (defun my/copy-from-osx ()
    (shell-command-to-string "pbpaste"))

  (defun my/paste-to-osx (text)
    (let ((process-connection-type nil))
      (let ((proc (start-process "pbcopy" "*Messages*" "pbcopy")))
        (process-send-string proc text)
        (process-send-eof proc))))
  (when-darwin-not-window-system
   (setq interprogram-cut-function #'my/paste-to-osx)
   (setq interprogram-paste-function #'my/copy-from-osx)))
  )

(unless IS-LINUX
  (setq command-line-x-option-alist nil)
  )
  
;; frame title
(setq frame-title-format
      '(buffer-file-name (:eval (abbreviate-file-name buffer-file-name))
                         (dired-directory dired-directory
                                          "%b")))

(defun my:font-initialize ()
  "Initialize fonts on window-system"
  (interactive)

  (cond
   ((eq window-system 'x)
    (let* ((size 12)
           (asciifont "Cica")
           (jpfont "Cica")
           (h (round (* size 12)))
           (jp-fontspec (font-spec :family jpfont)))
      (set-face-attribute 'default nil :family asciifont :height h)
      (unless (string= asciifont jpfont)
        (set-fontset-font nil 'unicode jp-fontspec nil 'append))
      (when (featurep 'all-the-icons)
        (set-fontset-font nil 'unicode (font-spec :family (all-the-icons-alltheicon-family)) nil 'append)
        (set-fontset-font nil 'unicode (font-spec :family (all-the-icons-material-family)) nil 'append)
        (set-fontset-font nil 'unicode (font-spec :family (all-the-icons-fileicon-family)) nil 'append)
        (set-fontset-font nil 'unicode (font-spec :family (all-the-icons-faicon-family)) nil 'append)
        (set-fontset-font nil 'unicode (font-spec :family (all-the-icons-octicon-family)) nil 'append)
        (set-fontset-font nil 'unicode (font-spec :family (all-the-icons-wicon-family)) nil 'append))
      (message (format "Setup for %s with %f" asciifont size))))
   (t
    (message "Not have window-system"))))

; font 設定を反映
(my:font-initialize)

; long file adapt. 
(global-so-long-mode)

;6.3. profilerを終了する
(when my/enable-profile
  (profiler-report)
  (profiler-stop))

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:background "#282a36" :foreground "#f8f8f2"))))
 '(goggles-added ((t (:background "#010101"))))
 '(goggles-changed ((t (:background "#c9ba99"))))
 '(goggles-removed ((t (:background "#fabfbb"))))
 '(org-done ((t (:foreground "PaleGreen" :weight normal :strike-through t))))
 '(org-headline-done ((((class color) (min-colors 16) (background dark)) (:foreground "LightSalmon" :strike-through t)))))

(message "init.el end.")
