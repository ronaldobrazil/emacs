;;; org-table-bar.el --- Highlight cells between [ and ] in org tables -*- lexical-binding: t; -*-

;; orgテーブル内の [ と ] を含むセル間をオーバーレイでハイライトする。
;; ガントチャート風のバー表示に使える。
;;
;; 認識パターン:
;;   | [  |    | ]  |  セル間バー（[ セル先頭 〜 ] セル末尾）
;;   | [] |              単一セルバー
;;   | [ MTG |    | ] 納品 |  テキスト付きも認識
;;
;; サフィックスで色分け:
;;   ]A / []A  赤（優先度高）
;;   ]B / []B  青（既定、サフィックスなしと同じ）
;;   ]C / []C  緑（優先度低）
;;   ]X / []X  灰（その他）
;;
;; after-change-functions + idle timer (0.3s) で自動再描画。

(defface org-table-bar-face
  '((t :background "#5b82c4" :foreground "#ffffff"))
  "Face for the bar region between [ and ] in org tables."
  :group 'org-table-bar)

(defface org-table-bar-face-a
  '((t :background "#c45b5b" :foreground "#ffffff"))
  "Face for ]A bars (high priority)."
  :group 'org-table-bar)

(defface org-table-bar-face-c
  '((t :background "#3d7a5a" :foreground "#ffffff"))
  "Face for ]C bars (low priority)."
  :group 'org-table-bar)

(defface org-table-bar-face-x
  '((t :background "#888888" :foreground "#ffffff"))
  "Face for ]X bars (misc)."
  :group 'org-table-bar)

(defvar org-table-bar--suffix-faces
  '((?A . org-table-bar-face-a)
    (?B . org-table-bar-face)
    (?C . org-table-bar-face-c)
    (?X . org-table-bar-face-x))
  "Alist mapping suffix characters to faces.")

(defun org-table-bar--detect-face (str)
  "Detect bar face from suffix in STR (e.g. \"]A\", \"[]C\")."
  (if (string-match "\\][ABCX]" str)
      (or (cdr (assq (aref str (1+ (match-beginning 0)))
                      org-table-bar--suffix-faces))
          'org-table-bar-face)
    'org-table-bar-face))

(defvar-local org-table-bar--overlays nil
  "List of overlays created by org-table-bar.")

(defun org-table-bar--clear ()
  "Remove all bar overlays."
  (mapc #'delete-overlay org-table-bar--overlays)
  (setq org-table-bar--overlays nil))

(defun org-table-bar--parse-cells ()
  "Parse the current table row into a list of (BEG . END) cell regions.
Each pair represents the region between two | delimiters."
  (let ((line-beg (line-beginning-position))
        (line-end (line-end-position))
        cells pipe-positions)
    (save-excursion
      (goto-char line-beg)
      (while (search-forward "|" line-end t)
        (push (point) pipe-positions)))
    (setq pipe-positions (nreverse pipe-positions))
    ;; pipe-positions = 各 | の直後の位置
    ;; 隣接する | のペアからセル範囲を作る
    (let ((pipes pipe-positions))
      (while (cdr pipes)
        (push (cons (car pipes) (1- (cadr pipes))) cells)
        (setq pipes (cdr pipes))))
    (nreverse cells)))

(defun org-table-bar--cell-content-trimmed (beg end)
  "Return the trimmed text between BEG and END."
  (string-trim (buffer-substring-no-properties beg end)))

(defun org-table-bar--render ()
  "Scan buffer for org table rows and highlight cells between [ and ]."
  (org-table-bar--clear)
  (save-excursion
    (goto-char (point-min))
    (while (not (eobp))
      (when (and (org-at-table-p)
                 (not (org-at-table-hline-p)))
        (let* ((cells (org-table-bar--parse-cells))
               (len (length cells))
               (i 0)
               in-bar bar-beg)
          (while (< i len)
            (let* ((cell (nth i cells))
                   (content (org-table-bar--cell-content-trimmed (car cell) (cdr cell)))
                   (clean (replace-regexp-in-string
                           "\\[\\[[^]]*\\]\\(?:\\[[^]]*\\]\\)?\\]" "" content)))
              (cond
               ;; [] を含むセル（1セル完結バー）
               ((and (not in-bar) (string-match-p "\\[\\]" clean))
                (let ((ov (make-overlay (car cell) (cdr cell))))
                  (overlay-put ov 'face (org-table-bar--detect-face clean))
                  (overlay-put ov 'org-table-bar t)
                  (push ov org-table-bar--overlays)))
               ;; [ を含むセル → バー開始
               ((and (not in-bar) (string-match-p "\\[" clean))
                (setq in-bar t
                      bar-beg (car cell)))
               ;; ] を含むセル → バー終了
               ((and in-bar (string-match-p "\\]" clean))
                (let ((ov (make-overlay bar-beg (cdr cell))))
                  (overlay-put ov 'face (org-table-bar--detect-face clean))
                  (overlay-put ov 'org-table-bar t)
                  (push ov org-table-bar--overlays))
                (setq in-bar nil))))
            (setq i (1+ i)))))
      (forward-line 1))))

(defun org-table-bar--after-change (&rest _)
  "Re-render bars after buffer changes (debounced via idle timer)."
  (when (timerp org-table-bar--timer)
    (cancel-timer org-table-bar--timer))
  (setq org-table-bar--timer
        (run-with-idle-timer 0.3 nil
                             (lambda (buf)
                               (when (buffer-live-p buf)
                                 (with-current-buffer buf
                                   (org-table-bar--render))))
                             (current-buffer))))

(defvar-local org-table-bar--timer nil)

;;;###autoload
(define-minor-mode org-table-bar-mode
  "Minor mode to highlight cells between [ and ] in org tables."
  :lighter " TBar"
  (if org-table-bar-mode
      (progn
        (org-table-bar--render)
        (add-hook 'after-change-functions #'org-table-bar--after-change nil t))
    (org-table-bar--clear)
    (remove-hook 'after-change-functions #'org-table-bar--after-change t)))

(provide 'org-table-bar)
;;; org-table-bar.el ends here
