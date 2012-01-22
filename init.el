;;; Emacs TO DO
;;; - thing-opt でカーソル周りのオブジェクトを選択できるようになったので，
;;;   あとは vim ライクにオブジェクトをマーク，キルしたい．
;;; - yatex のインクルード構造ブラウザでメインファイルをいちいち
;;;   聞かないようにする
;;; - xdvi-search でのフォーカス操作。defadvice で前置引数を使いたい
;;;   現在のところ，フォーカスを移動するのは wmctrl でできるが，毎回移動するのはめんどい
;;; - 正規表現に一致する行に bm
;;; - 起動時間測定をもっと賢くする
;;; - init.el 分割
;;; - 折り返しする column をハイライトするようなモード。折り返しの大体の目安がほしい
;;; - UWSC のメジャーモードを作る．generic じゃコントロールできん．
;;; - org-mode のタグをつける際に，
;;; - windows.el が使えた。少々改良できたらいいな。タブとか、*---* なバッファの復元とか
;;; - IME の ON/OFF に連動してカーソル色を変えたりを、自作したほうがいい気がする
;;; - one-key の代わりに現在のキーバインドを動的に表示できる elisp

;;; 起動時間を測定する
;;; http://aikotobaha.blogspot.com/2010/08/gnupack-ntemacs23-dotemacs.html より
;;; http://ubulog.blogspot.com/2009/08/emacs.html
(defvar my-measure-init-time-file (expand-file-name ".init_time" user-emacs-directory)
  "File name to write out initialization time.")

(defvar my-measure-previous-time before-init-time "Time at previous point.")
(defvar my-measure-current-time before-init-time "Time at current point.")

(defun my-measure-between-time (pre cur)
  "Return time between two points in msec.

PRE time needs to be before CUR time."
  (let* ((most  (- (nth 0 cur) (nth 0 pre)))
         (least (- (nth 1 cur) (nth 1 pre)))
         (msec  (/ (- (nth 2 cur) (nth 2 pre)) 1000)))
    (+ (* 65536 1000 most) (* 1000 least) msec)))

(defun my-measure-message-time (message)
  ""
  (setq my-measure-previous-time my-measure-current-time)
  (setq my-measure-current-time (current-time))
  (let ((between-time (my-measure-between-time my-measure-previous-time
                                               my-measure-current-time)))
    (with-current-buffer (get-buffer-create " *measure time*")
      (insert (format "%d msec. %s\n" between-time message)))))

(defun my-measure-init-time ()
  (let* ((system-time-locale "C")
         (init-time (my-measure-between-time before-init-time after-init-time)))
    (with-temp-buffer
      (when (file-exists-p my-measure-init-time-file)
        (insert-file-contents-literally my-measure-init-time-file)
        (goto-char (point-min)))
      (insert (format "%6d msec elapsed to initialize. " init-time) ; かかった時間
              (car (split-string (emacs-version) "\n")) ; Emacs のバージョンとハードウェアの名前
              (format-time-string " at %Y-%m-%d (%a) %H:%M:%S" after-init-time nil) ; 起動した日時
              (format " on %s@%s\n" user-login-name system-name)) ; ユーザ名とマシン名
      (write-region (point-min) (point-max) my-measure-init-time-file)
      (kill-buffer))))

; より正確を期すため `after-init-hook' 中に `after-init-time' をはかる
(add-hook 'after-init-hook
          '(lambda ()
             (setq after-init-time (current-time))
             (my-measure-message-time "after-init-hook.")
             (my-measure-init-time))
          t)

;;; OSの判別，固有の設定
;;; 2010-11-08 (Mon)
;;; http://d.hatena.ne.jp/marcy_o/20081208/1228742294 より
(defconst dropbox-directory (expand-file-name "~/Dropbox")) ; 語尾に / を含めるか含めないか悩むな

(defun macp ()
  (eq system-type 'darwin))
(defun linuxp ()
  (eq system-type 'gnu/linux))
(defun bsdp ()
  (eq system-type 'gnu/kfreebsd))
(defun winp ()
  (eq system-type 'windows-nt))

;; なんか最新版をビルドしたやつはこれをつけたほうがいいらしい？
;; これがないと ispell が動かなかった。ispell に限らんかもしれんが
(setq debian-emacs-flavor 'emacs-snapshot)

;; add load-path
;; http://masutaka.net/chalow/2009-07-05-3.html 参考に
(defconst my-individual-elisp-directory
  (list (expand-file-name "site-lisp" user-emacs-directory)
	(expand-file-name "my-lisp" user-emacs-directory)
	(expand-file-name "package" user-emacs-directory))
  "The directory for my elisp file.")
; サブディレクトリも含めて追加
(dolist (dir my-individual-elisp-directory)
  (when (and (stringp dir) (file-directory-p dir))
    (let ((default-directory dir))
      (add-to-list 'load-path dir)
      (normal-top-level-add-subdirs-to-load-path))))
;; 普通に追加
(add-to-list 'load-path (expand-file-name "auto-install" user-emacs-directory))

;;; setting PATH in Windows
(when (winp)
  (setenv "PATH" (concat (expand-file-name "c:/cygwin/bin") ";"
                         (getenv "PATH")))
  (add-to-list 'exec-path "c:/cygwin/bin")
  )


;;; package.el
;;; elisp のパッケージ管理をする
;;; (auto-install-from-url "http://repo.or.cz/w/emacs.git/blob_plain/1a0a666f941c99882093d7bd08ced15033bc3f0c:/lisp/emacs-lisp/package.el")
;;; http://tromey.com/elpa/install.html にかかれている方法でインストールすると，
;;; 古いバージョンの package.el がインストールされる．糞だな．
(when (load (expand-file-name "~/.emacs.d/package/package.el") t)
  ;; directory to install packages
  (setq package-user-dir (concat user-emacs-directory "package"))
  ;; location to get package informations
  (add-to-list 'package-archives '("elpa" . "http://tromey.com/elpa/"))
  (add-to-list 'package-archives '("marmalade" . "http://marmalade-repo.org/packages/"))
  (add-to-list 'package-archives '("SC" . "http://joseito.republika.pl/sunrise-commander/"))
  ;; key bind
  (define-key package-menu-mode-map (kbd "k") 'previous-line)
  (define-key package-menu-mode-map (kbd "j") 'next-line)

  ;; To mark line when cursor is not at beginning-of-line
  (defadvice package-menu-get-status (before package-menu-get-status-modify activate)
    (beginning-of-line))

  (package-initialize))

(my-measure-message-time "Basic setting.")
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;; 自作関数 ;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; find-file 時にバッファ名に補助的な文字列を追加する
(defadvice find-file (after find-file-rename activate)
  ;; when open snippet file, append [snippet]
  (when (string-match "/snippets/" (or (buffer-file-name) ""))
    (rename-buffer (concat (buffer-name) " [snippet]")))
  )


;;; other-window でコマンド実行するマイナーモード
(defun command-other-window-execute (command)
  (with-selected-window (other-window-for-scrolling)
    (funcall command)))

(defvar command-other-window-mode-keymap (make-sparse-keymap))
(define-key command-other-window-mode-keymap (kbd "H-j")
  '(lambda () (interactive) (command-other-window-execute 'next-line)))
(define-key command-other-window-mode-keymap (kbd "H-k")
  '(lambda () (interactive) (command-other-window-execute 'previous-line)))

(define-minor-mode command-other-window-mode
  "Execute command in other window."
  :global nil
  :group 'command-other-window
  :init-value nil
  :lighter " COW"
  :keymap command-other-window-mode-keymap)

;;; どっかからとってきたはずだけど忘れた．
(defun anything-my-minibuffer-complete ()
  ""
  (interactive)
  (lexical-let*
      ((beg (field-beginning))
       (end (field-end))
       (string (buffer-substring beg end))
       (comp (completion-try-completion
		      string
		      minibuffer-completion-table
		      minibuffer-completion-predicate
		      (- (point) beg))))
    (insert (car comp)))
  )
(define-key minibuffer-local-map (kbd "C-s") 'anything-my-minibuffer-complete)

;;; 2011-09-05 (Mon)
;;; 数値をインクリメント，デクリメント
;;; http://d.hatena.ne.jp/gongoZ/20091222/1261454818
(defun my-increment-string-as-number (number)
  "Replace progression string of the position of the cursor
by string that added NUMBER.
Interactively, NUMBER is the prefix arg.

examle:
At the cursor string \"12\"

M-x increment-string-as-number ;; replaced by \"13\"
C-u 10 M-x increment-string-as-number ;; replaced by \"22\"

At the cursor string \"-12\"

M-x increment-string-as-number ;; replaced by \"-11\"
C-u 100 M-x increment-string-as-number ;; replaced by \"88\""
  (interactive "P")
  (let ((col (current-column))
        (p (if (integerp number) number 1)))
    (skip-chars-backward "-0123456789")
    (or (looking-at "-?[0123456789]+")
        (error "No number at point"))
      (replace-match
       (number-to-string (+ p (string-to-number (match-string 0)))))
    (move-to-column col)))
(define-key global-map (kbd "M-i") 'my-increment-string-as-number)

;;; 2011-08-14 (Sun)
;;; ウィンドウを対話的にリサイズ
;;; http://d.hatena.ne.jp/khiker/20100119/window_resize
(defun my-window-resizer ()
  "Control window size and position."
  (interactive)
  (let ((window-obj (selected-window))
        (current-width (window-width))
        (current-height (window-height))
        (dx (if (= (nth 0 (window-edges)) 0) 1
              -1))
        (dy (if (= (nth 1 (window-edges)) 0) 1
              -1))
        action c)
    (catch 'end-flag
      (while t
        (setq action
              (read-key-sequence-vector (format "size[%dx%d]"
                                                (window-width)
                                                (window-height))))
        (setq c (aref action 0))
        (cond ((= c ?l)
               (enlarge-window-horizontally dx))
              ((= c ?h)
               (shrink-window-horizontally dx))
              ((= c ?j)
               (enlarge-window dy))
              ((= c ?k)
               (shrink-window dy))
              ;; otherwise
              (t
               (let ((last-command-char (aref action 0))
                     (command (key-binding action)))
                 (when command
                   (call-interactively command)))
               (message "Quit")
               (throw 'end-flag t)))))))

;;; 2011-08-10 (Wed)
;;; emacsclient の focus 制御のため
;;; http://d.hatena.ne.jp/syohex/20110127/1296141148
(when (and (linuxp) (executable-find "emacs_server_start.pl"))
  (defadvice server-start
    (after server-start-after-write-window-id ())
    (call-process "emacs_serverstart.pl"
                  nil nil nil
                  (number-to-string (emacs-pid))
                  (if window-system
                      "x"
                    "nox")))
  (ad-activate 'server-start))

;;; 2011-08-08 (Mon)
;;; ミニバッファでカーソルの左側の "/" まで文字を削除
;;; 1つ上のディレクトリを指定するのに便利
(defun my-minibuffer-delete-parent-directory ()
  "Delete one level of directory path."
  (interactive)
  (let ((current-pt (point)))
    (when (re-search-backward "/[^/]+/?" nil t)
      (forward-char 1)
      (delete-region (point) current-pt))))
(define-key minibuffer-local-map (kbd "M-^") 'my-minibuffer-delete-parent-directory)

;;; 2011-07-26 (Tue)
;;; org-mode の星の可視をトグルする関数
(defun org-my-toggle-hide-stars ()
  "Toggle whether hide org-mode leading stars."
  (interactive)
  (if org-hide-leading-stars
      (progn (setq org-hide-leading-stars nil)
             (message "Not hide org-mode leading stars."))
    (setq org-hide-leading-stars t)
    (message "Hide org-mode leading stars."))
  ;; restart font-lock-mode
  (font-lock-mode 0)
  (font-lock-mode 1))
;; 作っては見たものの，org-indent-mode すると自動的に
;; 星が不可視になるので，そっちの方が見やすいね．

;;; 2011-07-22 (Fri)
;;; C-j と M-j の機能を統合した関数
;; (defun my-dwim-newline-and-indent ()
;;   "Excute newline-and-indent or indent-new-comment-line as appropriate."
;;   (interactive)
;;   (let (search-flag
;;         (eol-bound (point))
;;         (search-string (concat "^\\s *" comment-start)))
;;     (save-excursion
;;       (beginning-of-line)
;;       (setq search-flag (re-search-forward search-string eol-bound t)))
;;     (if search-flag
;;         (indent-new-comment-line)
;;       (newline-and-indent))))
;; (define-key global-map (kbd "C-j") 'my-dwim-newline-and-indent)
;; わざわざこんなん作ったけど，最初から C-j に indent-new-comment-line を
;; 割り当てればいい話だった．
(define-key global-map (kbd "C-j") 'indent-new-comment-line)

;;; 2011-06-28 (Tue)
;;; http://www.fan.gr.jp/~ring/Meadow/meadow.html
;;; active な region を削除する
;; (defadvice delete-char
;;   (around delete-region-by-delete-char activate)
;;   (if (and transient-mark-mode mark-active)
;;       (delete-region (region-beginning) (region-end))
;;     ad-do-it))

;; (defadvice delete-backward-char
;;   (around delete-region-by-delete-backward-char activate)
;;   (if (and transient-mark-mode mark-active)
;;       (delete-region (region-beginning) (region-end))
;;     ad-do-it))

;;; 2011-06-26 (Sun)
;;; https://github.com/kik/sandbox/blob/master/emacs/show-char.el
;;; モードラインに現在の文字の説明を表示するマイナーモード
;; (defun show-current-char ()
;;   (let ((ch (following-char)))
;;     (format " [U+%04X %s] " ch (get-char-code-property ch 'name))))

;; (easy-mmode-define-minor-mode show-char-mode
;;   "Toggle Show char mode."
;;   nil
;;   (:eval (show-current-char)))

;;; 2011-06-15 (Wed)
;;; http://d.hatena.ne.jp/khiker/20100721/doya
(defun doya-show ()
  (interactive)
  (let ((doya-faces '("                      ＿＿＿  まぁ確かに・・・
                    ／⌒  '' ⌒＼
                  ／（ ● ) (● )＼             Emacsを立ち上げたのはお前
                ／::⌒  ,    ゝ⌒::＼    (⌒)
                |       `ｰ=-'     |    ﾉ~.ﾚ-r┐､
                ＼               ／   ノ  |.| |
.         ,  ⌒ ´  ＼     ￣   ´ !〈￣｀- Lλ_ﾚﾚ
        /    __       ヽ        |  ￣｀ー‐-‐‐´
.      〃 ,. --ミ        ヽ     i   |/ハ ／
      ji／    ￣｀          ヽ  |\n"

                      "                      ＿＿＿
                    ／ノ '' ⌒＼
                  ／（ ● ) (● )＼でも、この画面まで来れたのは俺のおかげ
                ／::⌒   ,   ゝ⌒::＼
                |       ﾄ==ｨ'     |
    _,rｰく´＼  ＼,--､    `ー'    ／
. ,-く ヽ.＼ ヽ Y´  ／   ー    ´ !｀ｰ-､
  {  -!  l _｣_ﾉ‐′/ ヽ            |    ∧
. ヽ  ﾞｰ'´ ヽ    /     ヽ        i  |/ハ
  ｀ゝ、    ﾉ  ノ         ヽ     |\n"


                      "                      ＿＿＿
                    ／ヽ ''ノ＼
                  ／（ ● ) (● )＼
                ／::⌒    ､＿ゝ⌒::＼   (⌒)          だろっ？
                |         -       |   ﾉ ~.ﾚ-r┐､
                ＼               ／  ノ_  |.| |
.         ,  ⌒ ´  ＼     ￣   ´ !〈￣  ｀-Lλ_ﾚﾚ
        /    __       ヽ        |  ￣｀ー‐-‐‐´
.      〃 ,. --ミ        ヽ     i    |/ハ  ／
      ji／    ￣｀          ヽ  |\n"


                      "                                                         ＿＿＿_
      .                                               ／_ノ   ヽ､_＼
                                                  oﾟ(（○)    (（○）)ﾟo   ,. -- ､
                                               ／::::::⌒（__人__）⌒::::::  /      __,＞─ ､
                                               |          |r┬-|        /                  ヽ
                                               |          |  |   |      ｛                      |__
                                               |          |  |   |       ｝   ＼             ,丿  ヽ
    ＿＿＿,.-------､            .         |          |  |   |      /    ､  ｀┬----‐１      }
（⌒        _,.--‐       ｀ヽ        .         |          |  |   |   .／      `￢.|         l      ﾉヽ
  ` ー-ｧ'' / / r'⌒)        ￣￣`ー‐--  ＼         `ー'ｫ  /        ､ !_/.ｌ        l      /   ｝
          ＼＼＼_／     ノ＿＿＿             `''ー          {           ＼         l     /    ,'
              ￣ `（＿,r'             ￣`ー-､        .     ／ ＼          ´｀ヽ.__,ノ    /    ﾉ
                                               ／          ／        ＼         ヽ､＼ __,ノ  ／
                                            ／          ／              ￣ ヽ､_    〉 ,!､__／
                                           /    ＿   く                           ￣
                                         ／ ／    ＼  ＼
                                      ／ ／          ＼  ＼
                  .                ／ ／              ／  ／
                               ／  ／                ゝ、  ヽ
                            ／  ／                       ￣
                         ／    /
                        r＿__ノ\n"



                 "          ／￣￣  ＼
        ／ﾉ(  _ノ   ＼
        |  ⌒(（ ●）（●）             うぜえ！
        .|         （__人__）  /⌒l
         |          ｀ ⌒´ﾉ  |`'''|
        ／ ⌒ヽ         }   |   |                      ＿＿＿_
     ／   へ    ＼     }__/  /                      ／  ─    —＼
  ／  ／  |           ノ    ノ                     ／●））    （（●＼ . ’,  ･   ぐぇあ
( _ ノ       |           ＼´             ＿     ／       （__人__）’,∴＼ ,   ’
             |              ＼＿,, -‐ ''\"   ￣￣ﾞ''—---└'´￣｀ヽ/    >  て
             .|                                                ＿＿ ノ  ／   （
              ヽ                      ＿,, -‐ ''\"￣ヽ､￣  `ー'´   ／   ｒ'\"￣
                 ＼              , '´                   /            .|
                    ＼          (                     /              |
                       ＼        ＼                /\n"

))
        ol)
    (dolist (i doya-faces)
      (setq ol (make-overlay (window-start) (point-max)))
      (setq i (propertize i 'face 'highlight))
      (unwind-protect
          (progn (overlay-put ol 'after-string i)
                 (overlay-put ol 'invisible t)
                 (redisplay)
                 (sleep-for 1.5)
                 (discard-input))
        (delete-overlay ol)))))
;(add-hook 'emacs-startup-hook 'doya-show t)

;;; 2011-04-10 (Sun)
;;; http://d.hatena.ne.jp/khiker/20091120/emacs_require_load_macro
;;; http://www.sodan.org/~knagano/emacs/dotemacs.html
;;; 安全な require, load マクロ
;; use like this (my-safe-require 'skk body)
(defmacro my-safe-require (feature &rest body)
  (declare (indent 1))
  `(if (require ,feature nil t)
       (progn
         (message "Require success: %s from %s" ,feature (locate-library (symbol-name ,feature)))
         ,@body)
     (message "Require error: %s" ,feature)))

;; use like this (my-safe-load "skk" body)
(defmacro my-safe-load (name &rest body)
  (declare (indent 1))
  `(if (load ,name t)
       (progn
         (message "Load success: %s from %s" ,name (locate-library ,name))
         ,@body)
     (message "Load error: %s" ,name)))

;;; 2011-02-27 (Sun)
;;; windows.el のタブを作りたい！
(defvar win:my-list nil nil)
(defun win:my-update-list ()
  "Update win:my-list"
  (setq win:my-list nil)
  (let (name)
    (dotimes (itr (length win:names) win:my-list)
      (unless (string= (setq name (aref win:names itr)) "")
        ;(print (format "%d: %s" itr name))))))
        (setq win:my-list (cons (cons itr name) win:my-list))))
    (setq win:my-list (reverse win:my-list))))
(defun win:my-print-tab ()
  "Print window name list."
  (let (value
        (width 10))
    (dolist (element win:my-list value)
      (insert (concat (substring (format "%d %-100s" (car element) (cdr element)) 0 width) " ")))))
;; とりあえずウィンドウの番号と名前をある幅ごとに表示させることはできるようになった

;;; 2011-02-13 (Sun)
;;;  sequential-mark
;;;  C-u SPC SPC ... で順番にマーク履歴を辿れる
;; (defun my-sequential-mark ()
;;   "pop-to-mark"
;;   (interactive)
;;   (let* ((key-vector (recent-keys))
;;          (key-vector-index (1- (length key-vector))))
;;     (while (equal
;;             (single-key-description (aref key-vector key-vector-index))
;;             "C-SPC")
;;       (setq key-vector-index (1- key-vector-index)))
;;     (if (equal
;;          (single-key-description (aref key-vector key-vector-index))
;;          "C-u")
;;         (pop-to-mark-command)
;;       (set-mark-command nil))
;;     ))
;; (define-key global-map (kbd "C-SPC") 'my-sequential-mark)
;;; 2011-06-28 (Tue)
;;; もとからこのような機能があることに気づいた．残念すぎる
;; enable to pop mark-ring repeatedly like C-u C-SPC C-SPC ...
(setq set-mark-command-repeat-pop t)

;; 失敗作
;; (defadvice set-mark-command (around sequencial-mark activate)
;;   "sequencial mark"
;;   (if (eq last-command 'pop-to-mark-command)
;;       (progn
;;         (setq last-command 'pop-to-mark-command)
;;         (pop-to-mark-command))
;;     ad-do-it))



;;; 2011-02-10 (Thu)
;;; やさしいEmacs-Lisp講座 より
(defun my-resize-frame-interactively ()
  "対話的にフレームサイズを変えるのだ"
  (interactive)
  (let (key (width (frame-width)) (height (frame-height)))
    (catch 'quit
      (while t
        (setq key (read-char))
        (cond
         ((eq key ?n) (setq height (1+ height)))
         ((eq key ?p) (setq height (1- height)))
         ((eq key ?f) (setq width (1+ width)))
         ((eq key ?b) (setq width (1- width)))
         (t (throw 'quit t)))
        (modify-frame-parameters
         nil (list (cons 'width width) (cons 'height height)))))
    (message "おちまい")))

;;; 2011-02-07 (Mon)
(defun my-replace-touten ()
  "読点を．に統一"
  (interactive)
  (save-excursion
    (replace-string "。" "．" nil (point-min) (point-max))))
(defun my-replace-kuten ()
  "句点を，に統一"
  (interactive)
  (save-excursion
    (replace-string "、" "，" nil (point-min) (point-max))))

;;; 2011-02-06 (Sun)
;; my-count-lines-window が論理行を数えるため，長い行を折り返していると
;; 移動する行数がずれる．めんどくさいので気が向いたら修正する
(defun my-scroll-up-half-window ()
  "Scroll up half of window-height putting point on line relative to the selected window."
  (interactive)
  (let ((line (my-count-lines-window)))
    (scroll-up (/ (window-height) 2))
    (move-to-window-line line)))

(defun my-scroll-down-half-window ()
  "Scroll down half of window-height putting point on line relative to the selected window."
  (interactive)
  (let ((line (my-count-lines-window)))
    (scroll-down (/ (window-height) 2))
    (move-to-window-line line)))

;;; 2011-02-06 (Sun)
;; ちなみに数える行数は論理行である -> 物理行で数えるようにした
(defun my-count-lines-window ()
  "Count lines relative to the selected window. The number of line begins 0."
  (interactive)
  (let* (;(deactivate-mark nil)       ; prevent to deactivate region by this command
         (window-string (buffer-substring-no-properties (window-start) (point)))
         (line-string-list (split-string window-string "\n"))
         (line-count 0) line-count-list)
    (setq line-count (1- (length line-string-list)))
    (unless truncate-lines      ; consider folding back
      ;; `line-count-list' is list of the number of physical line which each logical line has.
      (setq line-count-list (mapcar '(lambda (str)
                                       (/ (my-count-string-columns str) (window-width)))
                                    line-string-list))
      (setq line-count (+ line-count (apply '+ line-count-list))))
    line-count))

;; count string width (columns)
(defun my-count-string-columns (str)
  "Count columns of string. The number of column begins 0."
  (with-temp-buffer
    (insert str)
    (current-column)))

;; (defun my-count-lines-window ()
;;   "Return line relative to the selected window. The number of line begins 0."
;;   (interactive)
;;   (if (equal (current-column) 0)
;;       (count-lines (window-start) (point))
;;     (1- (count-lines (window-start) (point)))))


;;; other-window を空気を読んで賢くする
;;; 2011-02-05 (Sat)
;;; Emacs テクニックバイブルより
;;; (/ 整数 整数) の返り値は当然整数なのです。気をつけましょう
(defun other-window-or-split (&optional prefix)
  "Split window if one window exists. Otherwise move a window."
  (interactive "P")
  (when (one-window-p)
    (if (> 3 (/ (float (window-width)) (window-height)))
        (split-window-vertically)
      (split-window-horizontally)))
  (if prefix
      (other-window -1)
    (other-window 1)))

;;; scroll-up, down でウィンドウに対する相対的なカーソル位置を動かさないアドバイス
(defadvice scroll-up (around scroll-up-relative activate)
  "Scroll up relatively without move of cursor."
  (let ((line (my-count-lines-window)))
    ad-do-it
    (move-to-window-line line)))

(defadvice scroll-down (around scroll-down-relative activate)
  "Scroll down relatively without move of cursor."
  (let ((line (my-count-lines-window)))
    ad-do-it
    (move-to-window-line line)))

;;; tex の表の整形
;;; 2011-02-05 (Sat)
(defun my-tex-table-align ()
  (interactive)
  (align-regexp (region-beginning) (region-end) "\\(\\s-*\\)&" 1 1 t))
(add-hook 'yatex-mode-hook
          '(lambda ()
             (YaTeX-define-key (kbd "C-a") 'my-tex-table-align)))

;;; uwsc-mode
;;; generic は簡単にメジャーモードを作ってくれる
;;; 2011-01-23 (Sun)
(define-generic-mode uwsc-generic-mode
  ;; コメントになる文字列の指定
  '("88")
  ;; キーワードの指定
  '("DIM" "PUBLIC" "CONST" "IF" "THEN" "ELSE" "IFB" "ELSEIF" "ENDIF" "SELECT" "CASE" "DEFAULT" "SELEND" "FOR"
    "NEXT" "TO" "STEP" "WHILE" "WEND" "REPEAT" "UNTIL" "CALL" "BREAK" "CONTINUE" "EXIT" "PRINT" "AND" "OR" "XOR"
    "MOD" "PROCEDURE" "FUNCTION" "FEND" "RESULT" "VAR" "DEF" "DLL" "OPTION" "THREAD" "CLASS" "ENDCLASS"
    "THIS" "GLOBAL" "WITH" "ENDWITH" "TEXTBLOCK" "ENDTEXTBLOCK" "HASHTBL" "TRY" "ENDTRY" "EXCEPT" "FINALLY"
    "dim" "public" "const" "if" "then" "else" "ifb" "elseif" "endif" "select" "case" "default" "selend" "for"
    "next" "to" "step" "while" "wend" "repeat" "until" "call" "break" "continue" "exit" "print" "and" "or" "xor"
    "mod" "procedure" "function" "fend" "result" "var" "def" "dll" "option" "thread" "class" "endclass"
    "this" "global" "with" "endwith" "textblock" "endtextblock" "hashtbl" "try" "endtry" "except" "finally"
    "Dim" "Public" "Const" "If" "Then" "Else" "Ifb" "Elseif" "Endif" "Select" "Case" "Default" "Selend" "For"
    "Next" "To" "Step" "While" "Wend" "Repeat" "Until" "Call" "Break" "Continue" "Exit" "Print" "And" "Or" "Xor"
    "Mod" "Procedure" "Function" "Fend" "Result" "Var" "Def" "Dll" "Option" "Thread" "Class" "Endclass"
    "This" "Global" "With" "Endwith" "Textblock" "Endtextblock" "Hashtbl" "Try" "Endtry" "Except" "Finally")
  ;; もうちょっと難しいキーワードの指定
  '(("[0-9]+" . font-lock-constant-face))
  ;; auto-mode-alist に追加
  '("\\.uws$")
  nil
  "Major mode for UWSC-generic")

;;; fullscreen
;;; 2011-01-17 (Mon)
;;; http://unaju.net/2010/12/emacs%E3%82%92%E3%83%95%E3%83%AB%E3%82%B9%E3%82%AF%E3%83%AA%E3%83%BC%E3%83%B3%E8%A1%A8%E7%A4%BA%E3%81%99%E3%82%8B/
(defun toggle-fullscreen ()
  (interactive)
  (set-frame-parameter nil 'fullscreen (if (frame-parameter nil 'fullscreen)
                                            nil 'fullboth)))
(define-key global-map (kbd "<f11>") 'toggle-fullscreen)

;;; ChangeLog と同じ形式で日付曜日挿入
;;; 2010-11-26 (Fri)
(defun my-insert-date (&optional time)
  (interactive)
  (unless (boundp 'time)
    (setq time (current-time)))
  (let ((system-time-locale "C"))
    (insert (format-time-string "%Y-%m-%d (%a)" time))))

(defun my-show-date (&optional time)
  (interactive)
  (unless (boundp 'time)
    (setq time (current-time)))
  (let ((system-time-locale "C"))
    (format-time-string "%Y-%m-%d (%a)" time)))

;;; print function
(setq my-print-command-format "nkf -e | e2ps -a4 -p -nh | lpr")
(defun my-print-region (begin end)
   (interactive "r")
   (shell-command-on-region begin end my-print-command-format))
(defun my-print-buffer ()
   (interactive)
   (my-print-region (point-min) (point-max)))

;;; scroll
;;; 2011-01-14 (Fri)
;; (defun my-scroll-1line-down ()
;;   (interactive)
;;   "1行スクロールダウンする．ポイントは移動しない．"
;;   (save-excursion
;;     (goto-char (window-start))
;;     (recenter 1)))
;; (defun my-scroll-1line-up ()
;;   (interactive)
;;   "1行スクロールアップする．ポイントは移動しない．"
;;   (save-excursion
;;     (goto-char (window-end))
;;     (recenter -1)))
;; 残念ながらすでに同じ目的の関数がありました

(my-measure-message-time "My original function.")
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;; 見た目とか ;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; rotate-thema.el
;;; フォント設定を順番に切り替えられる
;;; http://nintos.blogspot.com/2010/02/emacs.html
;; (prin1 (font-family-list)) で使えるフォントのファミリー名が見れるよ
;; (insert (prin1-to-string (x-list-fonts "*"))) にすると XLFD 表現で表示されるようだ
;(my-safe-load "rotate-theme")     ; これはフォントとかを順番にプレビューできる

;;; Ubuntu ではフォントのサイズが何でも，アスキーと日本語の高さはずれないが
;;; Windows だと縦幅がずれることがある．IPA モナー ゴシック 17 だとずれないのでこの設定で．
;;; 17pt だと縦幅はずれないが横幅がずれる．16pt だと逆なのかな？まだ高さがずれるほうがいいか
;;; 端末でフォント設定の意味はないので，条件分岐しておこう．
(when window-system
  ;; 標準のフォントサイズ
  (defvar my-font-size nil "Standard font size")
  (defvar my-font-str nil "Standard font string")
  (defvar my-font-set-str nil "Font string to create fontset")
  (cond ((linuxp)
         (setq my-font-size 16)
         (setq my-font-set-str "-unknown-Ricty-normal-normal-normal-*-%d-*-*-*-*-0-iso10646-1"))
        ((winp)
         (setq my-font-size 18)
         (setq my-font-set-str "-outline-Ricty-normal-normal-normal-*-%d-*-*-*-*-0-iso10646-1")))
  ;; それぞれのフォントサイズに対応したフォントセットを作る
  ;; http://f41.aaa.livedoor.jp/%7Ekonbu/emacs/font-setting.el
  (defvar my-font-size-list '(12 14 16 18 19 20 22 23 24 27 32))
  (let (size
        (size-list my-font-size-list))
    (while size-list
      (setq size (car size-list))
      (setq size-list (cdr size-list))
      (create-fontset-from-ascii-font (format my-font-set-str size) nil "myfont")))
  ;; 発音記号のフォント
  (set-fontset-font "fontset-default"
                    '#xf0
                    (font-spec :family "SILDoulos IPA93")) ; うまくいかん
  ;; (set-fontset-font "fontset-default"
  ;;                  'japanese-jisx0208
  ;;                  (font-spec :family "TakaoExゴシック")) ; なぜか fontset-default にするとうまくいく
  (defvar nandemo "あいうえおかきくけこさしすせそ")
  ;; フォントを設定
  (cond ((linuxp)
         (add-to-list 'default-frame-alist
               '(font . "-*-*-normal-normal-normal-*-16-*-*-*-*-*-fontset-myfont")))
        ((winp)
         (add-to-list 'default-frame-alist
               '(font . "-*-*-normal-normal-normal-*-18-*-*-*-*-*-fontset-myfont"))))
  ;; ;; アスキーフォント設定
  ;; (set-fontset-font nil '(    #x0 .   #x6ff) (font-spec :family "Ricty" :size my-font-size))
  ;; ;(set-face-attribute 'default nil :family "Inconsolata" :height 130)
  ;; ;; 日本語フォント設定
  ;; (set-fontset-font nil 'japanese-jisx0208 (font-spec :family "Ricty" :size my-font-size))
  )

;;; list-faces-display 用の文字列
;;; フォント幅テスト用の文字列．|
;;; 1234567890123456789012345678|
(setq list-faces-sample-text
"フォント幅テスト用の文字列．|
1234567890!\"#$%&'()~-^\\@=~`?|")

;; default-major-mode
(setq default-major-mode 'lisp-interaction-mode)

;use UTF-8
(set-default-coding-systems 'utf-8)
(coding-system-put 'utf-8 'category 'utf-8)
; Windows でフォルダ名が文字化けするので場合分け
; 条件が偽の場合が Windows の時だが特に設定しなくてもいいらしい
(if (linuxp)
      (setq file-name-coding-system 'utf-8-unix) ; default-file-name-coding-system がうまく
                                                 ; 自動判別してくれないので直接設定
      )
(set-language-environment "Japanese")
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-buffer-file-coding-system 'utf-8)
(setq default-buffer-file-coding-system 'utf-8)
(add-hook 'shell-mode-hook (lambda () (set-buffer-process-coding-system 'utf-8 'utf-8)))
;; よく分からんけど Ubuntu で「合計 8」とかが文字化けするのはこれで解決した
;; (add-hook 'dired-before-readin-hook
;;                         (lambda ()
;;                             (set (make-local-variable 'coding-system-for-read) 'utf-8)))

; frame configure
(setq default-frame-alist
      (append (list
               ;size & position
               '(width . 150)   ; 一行の字数
               '(height . 54)  ; 行数
               '(top . 0)    ; ディスプレイのx座標(ピクセル)
               '(left . 0)   ; ディスプレイのy座標(ピクセル)
               '(alpha . (95 85 60 40)) ; 不透明度
               ;color
               '(background-color . "Black") ; 背景の色
               '(foreground-color . "gainsboro") ; 文字の色
               '(cursor-color . "Yellow")     ; カーソルの色
               )
              default-frame-alist))
;(set-frame-parameter nil 'fullscreen 'fullboth)  ; なんか横幅が大きくなりすぎるのでコメントアウト

;タブ，全角スペース，半角スペースに色付け
;;(defface my-face-r-1 '((t (:background "gray15"))) nil)
(defface my-face-b-1 '((t (:background "gray30"))) nil)
(defface my-face-b-2 '((t (:background "gray20"))) nil)
(defface my-face-u-1 '((t (:foreground "SteelBlue" :underline t))) nil)
;;(defvar my-face-r-1 'my-face-r-1)
(defvar my-face-b-1 'my-face-b-1)
(defvar my-face-b-2 'my-face-b-2)
(defvar my-face-u-1 'my-face-u-1)

(defadvice font-lock-mode (before my-font-lock-mode ())
  (font-lock-add-keywords
   major-mode
   '(("　" 0 my-face-b-1 append)
     ("\t" 0 my-face-b-2 append)
     ("[ \t]+$" 0 my-face-u-1 append)
     ;;("[\r]*\n" 0 my-face-r-1 append)
     )))
(ad-enable-advice 'font-lock-mode 'before 'my-font-lock-mode)
(ad-activate 'font-lock-mode)

;;; key-bind
(define-key global-map (kbd "C-0") 'delete-window)
(define-key global-map (kbd "C-1") 'delete-other-windows)
(define-key global-map (kbd "C-2") 'split-window-vertically)
(define-key global-map (kbd "C-3") 'split-window-horizontally)
(define-key global-map (kbd "C-4") 'ctl-x-4-prefix)
(define-key global-map (kbd "C-5") 'ctl-x-5-prefix)
(defalias 'ctl-x-r-prefix ctl-x-r-map)
(define-key global-map (kbd "S-C-r") 'ctl-x-r-prefix)
(define-key global-map (kbd "C-t") 'other-window-or-split)
(define-key global-map (kbd "C-h") 'delete-backward-char)
(define-key global-map (kbd "M-h") 'backward-kill-word)
;(define-key global-map (kbd "C-S-k") '(lambda () (interactive) (kill-buffer)))
(define-key global-map (kbd "C-M-;") 'comment-or-uncomment-region)
(define-key global-map (kbd "H-n") '(lambda (arg) (interactive "p") (scroll-up arg)))
(define-key global-map (kbd "H-p") '(lambda (arg) (interactive "p") (scroll-down arg)))
(define-key global-map (kbd "H-u")
  '(lambda () (interactive) (scroll-down (/ (window-height) 2))))
(define-key global-map (kbd "H-d")
  '(lambda () (interactive) (scroll-up (/ (window-height) 2))))
(if (winp)
    (setq w32-apps-modifier 'hyper      ; apps キーを hyper キーにする
                                        ; nodoka でカタカナひらがなを app にしている前提
          w32-lwindow-modifier 'super)) ; 左Windows キーを super キーにする
(define-key global-map (kbd "S-SPC") 'self-insert-command) ; これがないと S-SPC が SPC に translate される

;; C-c keymap
(define-key mode-specific-map (kbd "c") 'compile)      ; C-c c で compile
(define-key mode-specific-map (kbd "s") 'shell)        ; C-c s でshell一発起動
(define-key mode-specific-map (kbd "A") 'align-regexp)

;; original key map (bind to C-q)
(defvar my-original-map (make-sparse-keymap)
  "My original keymap binded to C-q.")
(defalias 'my-original-prefix my-original-map)
(define-key global-map (kbd "C-q") 'my-original-prefix)
(define-key my-original-map (kbd "C-q") 'quoted-insert)
(define-key my-original-map (kbd "C-t") 'toggle-truncate-lines)
(define-key my-original-map (kbd "C-l") 'linum-mode)
(define-key my-original-map (kbd "C-w") 'my-window-resizer)
(define-key my-original-map (kbd "C-r")
  '(lambda () (interactive) (revert-buffer nil t t)))

;; emacsclientを使う
(my-safe-require 'server
  (cond ((not (server-running-p))
         (server-start))
        ((eq (server-running-p) :other)
         (server-start))))

(my-measure-message-time "Looks and key bind.")
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;; 動作設定 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; replace selected region by self-insert-command
;;; http://d.hatena.ne.jp/web7_77/20110705/1309885434
(delete-selection-mode t)

;;; set fill column. I fit it in Org-mode fill-column.
(setq default-fill-column 77)

;;; backup file を一箇所にまとめる
;;; 2011-07-21 (Thu)
;;; http://marigold.sakura.ne.jp/devel/emacs/backup_file/index.html
(setq make-backup-files t)
(setq backup-directory (expand-file-name "~/.bak"))
(unless (file-directory-p backup-directory)
  (make-directory-internal backup-directory))
(if (and (boundp 'backup-directory)
         (not (fboundp 'make-backup-file-name-original)))
    (progn
      (fset 'make-backup-file-name-original
            (symbol-function 'make-backup-file-name))
      (defun make-backup-file-name (filename)
        (if (and (file-exists-p (expand-file-name backup-directory))
                 (file-directory-p (expand-file-name backup-directory)))
            (concat (expand-file-name backup-directory)
                    "/" (file-name-nondirectory filename))
          (make-backup-file-name-original filename)))))

;;; 2011-06-21 (Tue)
(setq system-time-locale "C")

;;; hilight current row
;;; http://d.hatena.ne.jp/khiker/20070409/emacs_hl_line
(my-safe-require 'hl-line
  (global-hl-line-mode t)
  (defface my-hl-line-face
    '((((class color) (background dark))  ; カラーかつ, 背景が dark ならば,
       (:background "gray10" t))   ; 背景を黒に.
      (((class color) (background light)) ; カラーかつ, 背景が light ならば,
       (:background "gray90" t))     ; 背景を ForestGreen に.
      (t (:bold t)))
    "hl-line's my face")

  (setq hl-line-face 'my-hl-line-face)
  )

;;; backtrace when debugging
;(setq debug-on-error t)
;(setq debug-on-error nil)

;;; max-specpdl-size
(setq max-specpdl-size 6000)

;;; 初期作業ディレクトリを HOME にする
;;; 2011-04-15 (Fri)
(when (or (null (getenv "PWD"))
          (equal (getenv "PWD") "/"))
  (cd "~/"))

;;; Window title
;;; 2011-04-12 (Tue)
;;; http://cas.eedept.kobe-u.ac.jp/~arai/PCQA/3.7.html
;;; ファイル名 - emacs@システム名
(setq frame-title-format '("%b - " invocation-name "@" system-name))

;;; ヌルデバイス
;;; 2011-04-10 (Sun)
(setq-default null-device "/dev/null")

;;; 2011-03-25 (Fri)
;;; Windows での IME 関連
(when (winp)
  (setq default-input-method "W32-IME")         ;標準IMEの設定
  (w32-ime-initialize)                 ;IMEの初期化
  (set-cursor-color "yellow")          ;IME OFF時の初期カーソルカラー
  (setq w32-ime-buffer-switch-p t)     ;バッファ切り替え時にIME状態を引き継がない
  ;; IME の on/off を表示
  (setq-default w32-ime-mode-line-state-indicator "[--]")
  (setq w32-ime-mode-line-state-indicator "[--]")
  (setq w32-ime-mode-line-state-indicator-list
        '("[--]" "[あ]" "[--]"))
  ;; ; IME ON/OFF時のカーソルカラー
  ;; (defadvice ime-force-on (after ime-force-on-color activate)
  ;;   (set-cursor-color "green"))
  ;; (defadvice ime-force-off (after ime-force-off-color activate)
  ;;   (set-cursor-color "yellow"))
  ;; ime を on/off する関数のアドバイスでなんとかなるかと思いやってみた。
  ;; かなり意図通りの動きはするが、どうも動作が重いのでコメントアウト。コストが高すぎるか
  (add-hook 'input-method-activate-hook
    (lambda() (set-cursor-color "green")))
  (add-hook 'input-method-inactivate-hook
    (lambda() (set-cursor-color "yellow")))
  ;; できれば IME の状態はバッファローカルにしたい。ので、hook だけでは対応しきれない。
  ;; どないしよ

  ;; key-chord が無効になってしまうのは以下で解決できた
  ;; http://d.hatena.ne.jp/grandVin/20080917/1221653750
  (defadvice toggle-input-method (around toggle-input-method-around activate)
    (let ((input-method-function-save input-method-function))
      ad-do-it
      (setq input-method-function input-method-function-save)))
  ;; isearch で IME を off にする
  (wrap-function-to-control-ime 'isearch-forward t nil)
  (wrap-function-to-control-ime 'isearch-forward-regexp t nil)
  (wrap-function-to-control-ime 'isearch-backward t nil)
  (wrap-function-to-control-ime 'isearch-backward-regexp t nil)
)

;;; 2011-02-15 (Tue)
;; EOF 以降の空行を表示
(setq-default indicate-empty-lines t)

;;; eval したとき結果が長くても折りたたまない
;;; 2011-02-05 (Sat)
(setq eval-expression-print-level nil
      eval-expression-print-length nil
      eval-expression-debug-on-error nil)

;;; proxy 設定
;(setq url-proxy-services '(("http" . "localhost:1080")))

;;; *scratch*を消さない
;;; 2011-01-05 (Wed)
(defun my-make-scratch (&optional arg)
  (interactive)
  (progn
    ;; "*scratch*" を作成して buffer-list に放り込む
    (set-buffer (get-buffer-create "*scratch*"))
    (funcall initial-major-mode)
    (erase-buffer)
    (when (and initial-scratch-message (not inhibit-startup-message))
      (insert initial-scratch-message))
    (or arg (progn (setq arg 0)
                   (switch-to-buffer "*scratch*")))
    (cond ((= arg 0) (message "*scratch* is cleared up."))
          ((= arg 1) (message "another *scratch* is created")))))

(add-hook 'kill-buffer-query-functions
          ;; *scratch* バッファで kill-buffer したら内容を消去するだけにする
          (lambda ()
            (if (string= "*scratch*" (buffer-name))
                (progn (my-make-scratch 0) nil)
              t)))

(add-hook 'after-save-hook
          ;; *scratch* バッファの内容を保存したら *scratch* バッファを新しく作る
          (lambda ()
            (unless (member (get-buffer "*scratch*") (buffer-list))
              (my-make-scratch 1))))

;;; Xwindow: クリップボード
;;; Emacs: キルリング
;;; terminal: オリジナルのコピーバッファ？
;;; terminalの中クリック: また別のバッファ？
;;; screen: オリジナルのコピーバッファ？
;;; Emacs のキルリングをクリップボードにおくる
;;; Emacs <-> Xwindow のコピーができる．ただし，gnome-terminal 除く
;;; gnome-terminal は C-S-v でクリップボードからペーストはできる
;;; screen からクリップボードにコピーはできるが、何故かキルリングには
;;; 同期されない。どうしたもんか
;;; 2010-12-31 (Fri)
(setq x-select-enable-clipboard t)
;; どうもデフォルトで t らしい
;; どうもデフォルトじゃなくなったらしい

;; ビープ音を消す
;(setq visible-bell t)    ; ビープ音の変わりに画面がフラッシュ
(setq ring-bell-function 'ignore)    ; エラー時に何も起こらなくなる

;; ツールバーを非表示
(tool-bar-mode 0)

;; メニューバーを非表示
(menu-bar-mode 0)

;; 編集中マウスカーソルを右上に
(mouse-avoidance-mode 'banish)

;; 直感バッファ移動(shift+カーソルキー)
(windmove-default-keybindings)

;;; 対応する括弧を光らせる
(show-paren-mode 1)

;; 長い行を折り返さない
;(setq truncate-lines t)
(setq truncate-partial-width-windows nil) ; これは分割されたウィンドウで折り返すか否かを制御する

;; 最大限色分けする
(setq font-lock-maximum-decoration t)

;; 起動時の画面を非表示
(setq inhibit-startup-message t)

;;; 下に行，列番号を表示する
(line-number-mode t)
(column-number-mode t)

;; ファイルを保存時に #! で始まっていればスクリプトとみなして実行権限を与える
(add-hook 'after-save-hook 'executable-make-buffer-file-executable-if-script-p)

;;; 時間を表示
;; 標準的なやつ
;(setq display-time-day-and-date nil)
;(setq display-time-24hr-format nil)
;; 日付時刻表示をカスタマイズ
(setq display-time-string-forms
      '((format-time-string "%Y-%m-%d (%a) %H:%M")))
(display-time-mode t)

; enable font-lock
(when (fboundp 'global-font-lock-mode) (global-font-lock-mode t))

; highlight selected region
(transient-mark-mode t)

; use bash
(cond ((winp)
       (cond ((equal system-name "MUSIMA")
              (setq shell-file-name "d:/cygwin/bin/bash.exe"
                    explisit-shell-file-name "d:/cygwin/bin/bash.exe"))
             (t
              (setq shell-file-name "bash.exe"
                    explisit-shell-file-name "bash.exe"))))
      ((linuxp)
       (setq explicit-shell-file-name "/bin/bash")
       (setq shell-file-name "/bin/bash")))

; hide inputting password
(add-hook 'comint-output-filter-functions 'comint-watch-for-password-prompt)

; handle escape sequences
;; (autoload 'ansi-color-for-comint-mode-on "ansi-color"
;;           "Set `ansi-color-for-comint-mode' to t." t)
;; (add-hook 'shell-mode-hook 'ansi-color-for-comint-mode-on)
;; shell で色を使うためのようだ。とりあえずコメントアウト

; インデントにタブを使わない設定
(setq-default indent-tabs-mode nil)

;; isearch
(define-key isearch-mode-map "\C-h" 'isearch-delete-char) ; isearch中の検索語の文字削除

;; ChangeLog-modeの設定
(setq user-full-name "KAI Tsunenobu")
(setq user-mail-address "kai@gavo.t.u-tokyo.ac.jp")

;; Add personal info directory
;; ここに追加したディレクトリの texinfo が読めるようになる
(setq Info-default-directory-list
      (cons (expand-file-name "~/.emacs.d/info/")
            Info-default-directory-list))

;; Display scroll-bar at left
(setq scroll-bar-mode 'left)
(toggle-scroll-bar 0)
;; 試しに scroll-bar なしでやってみる


;; M-x customize によって変更される設定
(custom-set-variables
  ;; custom-set-variables was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 '(safe-local-variable-values (quote ((TeX-master . "progress_report1.tex") (TeX-master . "/home/kai/Dropbox/works/tex_workspace/meeting/progress_report1.tex") (TeX-master . "bachelor_handout.tex") (TeX-master . "bachelor_thesis.tex") (clmemo-mode . t) (TeX-master . t)))))
(custom-set-faces
  ;; custom-set-faces was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 '(cfw:face-day-title ((t :background "grey10")))
 '(cfw:face-default-content ((t :foreground "green2")))
 '(cfw:face-header ((t (:foreground "maroon2" :weight bold))))
 '(cfw:face-holiday ((t :background "grey10" :foreground "purple" :weight bold)))
 '(cfw:face-regions ((t :foreground "cyan")))
 '(cfw:face-saturday ((t :foreground "blue" :weight bold)))
 '(cfw:face-select ((t :background "blue4")))
 '(cfw:face-sunday ((t :foreground "red" :weight bold)))
 '(cfw:face-title ((t (:foreground "darkgoldenrod3" :weight bold :height 2.0 :inherit variable-pitch))))
 '(cfw:face-today ((t :foreground: "cyan" :weight bold)))
 '(cfw:face-today-title ((t :background "red4" :weight bold)))
 '(col-highlight ((t (:background "gray10"))))
 '(linum ((t (:inherit (shadow default) :background "gray50" :foreground "yellow"))))
 '(scroll-bar ((t :foreground "magenta")))
 '(twittering-uri-face ((t (:foreground "cyan" :underline t)))))

(my-measure-message-time "Customize variable.")
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;; elispの準備，設定 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;; 標準elisp ;;;;;;;;;;;;;;;;
(my-safe-require 'outline
  ;; make outline-level buffer local variable
  (make-variable-buffer-local 'outline-level)
  (setq-default outline-level 'outline-level)
  (make-variable-buffer-local 'outline-regexp-alist)
  (define-key my-original-map (kbd "C-n") 'outline-next-visible-heading)
  (define-key my-original-map (kbd "C-p") 'outline-previous-visible-heading)
  (defadvice outline-next-visible-heading (after recenter-after activate)
    (recenter))
  (defadvice outline-previous-visible-heading (after recenter-after activate)
    (recenter))
  )

;;; tramp.el
;;; Edit file in remote host
(my-safe-require 'tramp
  (setq tramp-default-method (cond ((winp) "sshx")
                                   (t "ssh")))
  ;; config for using cygwin ssh on Windows. Please use "sshx" method.
  ;; http://www.emacswiki.org/emacs/TrampMode
  (when (winp)
    (nconc (cadr (assq 'tramp-login-args (assoc "ssh" tramp-methods)))
           '(("bash" "-i")))
    (setcdr (assq 'tramp-remote-sh (assoc "ssh" tramp-methods))
            '("bash -i")))
  ;; multi ssh
  (add-to-list 'tramp-default-proxies-alist
               '("athena\\(.gavo.t.u-tokyo.ac.jp\\)?" "\\`root\\'" "/kai@%h:"))
  (add-to-list 'tramp-default-proxies-alist
               '("rubner\\(.mydns.jp\\)?" "\\`root\\'" "/kai@%h:")))

;;; doc-view.el
;;; Emacs で pdf 閲覧
(my-safe-require 'doc-view
  (setq doc-view-continuous t)     ; move next page if execute next-line on bottom edge of image
  (define-key doc-view-mode-map (kbd "l") 'image-forward-hscroll)
  (define-key doc-view-mode-map (kbd "h") 'image-backward-hscroll)
  (define-key doc-view-mode-map (kbd "j") 'doc-view-next-line-or-next-page)
  (define-key doc-view-mode-map (kbd "k") 'doc-view-previous-line-or-previous-page)
  (define-key doc-view-mode-map (kbd "f") 'image-scroll-up)
  (define-key doc-view-mode-map (kbd "b") 'image-scroll-down)
  (define-key doc-view-mode-map (kbd "C-t") nil) ; もともとのコマンドは doc-view-show-tooltip

  ;; to move to next page on the edge of page
  (defadvice image-scroll-up (around image-scroll-up-or-next-page activate)
    (let ((vscroll (window-vscroll))
          (hscroll (window-hscroll)))
      ad-do-it
      (when (and doc-view-continuous (= vscroll (window-vscroll)))
        (doc-view-next-page)
        (image-bob)
        (set-window-hscroll (selected-window) hscroll))))
  (defadvice image-scroll-down (around image-scroll-down-or-previous-page activate)
    (let ((vscroll (window-vscroll))
          (hscroll (window-hscroll)))
      ad-do-it
      (when (and doc-view-continuous (= vscroll (window-vscroll)))
        (doc-view-previous-page)
        (image-eob)
        (set-window-hscroll (selected-window) hscroll))))
  )

;;; cua-mode.el
;;; 矩形範囲の編集を便利にする
;;; require とかはいらない模様
(cua-mode 1)
(setq cua-enable-cua-keys nil)

;;; longlines.el
;; (autoload 'longlines-mode "longlines.el"
;;   "Minor mode for automatically wrapping long lines." t)
;; スペースが入らないと意味が無いので，日本語では意味がなかった．

;;; gnus.el
;;; 2011-06-15 (Wed)

;;; open-dribble
;;; 2011-06-04 (Sat)
;;; キー入力をファイルに保存する
;; (defvar my-dribble-file (concat user-emacs-directory ".dribble") "dribble file")
;; (open-dribble-file my-dribble-file)
;; あんまり意味がなかった

;;; sh-script.el
;;; 2011-06-03 (Fri)
;;; sh-mode とかいろいろ
(my-safe-require 'sh-script
  (setq-default sh-basic-offset 2)
  (setq-default sh-indentation 2))

;;; eshell.el
;;; 2011-04-25 (Mon)
;;; Emacs lisp によるシェル
(my-safe-require 'eshell
  ;; 補完時に大文字小文字を区別しない
  (setq eshell-cmpl-ignore-case t)
  ;; 確認なしでヒストリ保存
  (setq eshell-ask-to-save-history (quote always))
  ;; 補完時にサイクルする
  (setq eshell-cmpl-cycle-completions t)
  ;;補完候補がこの数値以下だとサイクルせずに候補表示
  (setq eshell-cmpl-cycle-cutoff-length 5)
  ;; 履歴で重複を無視する
  (setq eshell-hist-ignoredups t)
  ;; prompt文字列の変更
  (defun my-eshell-prompt ()
    (concat (eshell/pwd) "\n$ " ))
  (setq eshell-prompt-function 'my-eshell-prompt)
  ;; (setq eshell-prompt-function
  ;;       '(lambda ()
  ;;         (concat "hoge "
  ;;                 (eshell/pwd)
  ;;                 ;(if (= (user-uid) 0) "]\n# " "]\n$ ")
  ;;                 )))
  ;; 変更したprompt文字列に合う形でpromptの初まりを指定(C-aで"$ "の次にカーソルがくるようにする)
  ;; これの設定を上手くしとかないとタブ補完も効かなくなるっぽい
  (setq eshell-prompt-regexp "^[^#$]*[$#] ")
  )
;; あまりうまく動きませんね．なんでやねん

;;; socks.el
;; (setq socks-override-functions 1)
;; (my-safe-require 'socks
;;   (setq socks-server '("Default" "localhost" "1080" 5))
;;   (defalias 'open-network-stream 'socks-open-network-stream))

;;; help-mode.el
(my-safe-require 'help-mode)

;;; info.el
(my-safe-require 'info
  (define-key Info-mode-map (kbd "M-n") nil) ; clone-buffer とかいう無駄なものが割り当てられてたので無効にする
  (define-key Info-mode-map (kbd "f") 'Info-scroll-up) ; 元のコマンドの Info-follow-reference の利用価値がまだわからない
  (define-key Info-mode-map (kbd "b") 'Info-scroll-down) ; もとはただの beginning-of-buffer なので問題ない
  (define-key Info-mode-map (kbd "F") 'Info-history-forward)
  (define-key Info-mode-map (kbd "B") 'Info-history-back)
  (define-key Info-mode-map (kbd "j") 'next-line)
  (define-key Info-mode-map (kbd "k") 'previous-line))

(defun my-Info-HaH ()
  "Follow a node by hit-a-hint.
リファレンス以外の部分も jaunte の候補が出てしまうので
改良の余地有り"
  (interactive)
  (jaunte)
  (Info-follow-nearest-node))
(define-key Info-mode-map (kbd "e") 'my-Info-HaH)


;;; ffap.el
;;; 2011-04-09 (Sat)
;;; カーソル近くのファイルや URL を find-file で開く
(ffap-bindings)
;; なかなかよい
;; もんだいは， one-key で上書きしている部分があるキーバインドがあるので
;; ffap が動かない部分がある．C-x 4 とか．other-window 系とか other-frame 系ですね

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; dired.el
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(my-safe-require 'dired)

;;; 2011-09-04 (Sun)
;;; dired-dd.el
;;; dired でドラッグアンドドロップを使う．実は dired のバッファに限らず使える
;;; マウスインターフェースのよう．dired-x を前提としているらしいので，ロードしておく
;;; http://www.asahi-net.or.jp/~pi9s-nnb/dired-dd-home.html
;; (add-hook 'dired-load-hook
;;           (function
;;            (lambda ()
;;              (load "dired-x")
;;              (if window-system (require 'dired-dd)))))
;; 何故かうまく動かないような気がする．コレ自体の問題じゃないかもだが．

;;; 2011-03-30 (Wed)
;;; ディレクトリ内のファイルを取得．エクスプローラ的な．
;; ディレクトリを先に表示
(setq ls-lisp-dirs-first t)             ; なんかどうも効果ないっぽい．この変数廃止された？
;; set ls option
;; Not display . and .. directories, and human readable file size.
(setq dired-listing-switches "-lAh")
;; wdired.el
;; dired で一括リネームできる
(my-safe-require 'wdired
  (define-key dired-mode-map (kbd "r") 'wdired-change-to-wdired-mode)
  (define-key wdired-mode-map (kbd "M-m") '(lambda () (interactive) (dired-move-to-filename)))
  )
;; sorter.el
;; 2011-03-30 (Wed)
;; dired のソートを拡張
;; http://www.bookshelf.jp/soft/meadow_25.html より
;; (auto-install-from-url "http://www.meadowy.org/~shirai/elips/sorter.el")
(my-safe-require 'sorter)
;; バッファ名に [Dired] を付加
;; 2011-04-15 (Fri)
;; うーん、どうもうまく働かない。というか readin-hook がどのタイミングのフックなのかわからん
;; 別の方法を探すか。
;; ふつうに dired-mode-hook でよかった
(add-hook 'dired-mode-hook
          '(lambda ()
             (when (eq major-mode 'dired-mode)
               (rename-buffer (concat
                               (buffer-name)
                               " ["
                               ;; Windows の場合はドライブレターを追加
                               (if (winp)
                                   (substring default-directory 0 2)
                                 "")
                               "Dired]")))))

;; 新しいバッファを作らないバッファ移動
;; http://www.bookshelf.jp/soft/meadow_25.html より
(defun dired-my-advertised-find-file ()
  (interactive)
  (let ((kill-target (current-buffer))
        (check-file (dired-get-filename)))
    (funcall 'dired-advertised-find-file)
    (if (file-directory-p check-file)
        (kill-buffer kill-target))))

(defun dired-my-up-directory (&optional other-window)
  "Run dired on parent directory of current directory.
Find the parent directory either in this buffer or another buffer.
Creates a buffer if necessary."
  (interactive "P")
  (let* ((dir (dired-current-directory))
         (up (file-name-directory (directory-file-name dir))))
    (or (dired-goto-file (directory-file-name dir))
        ;; Only try dired-goto-subdir if buffer has more than one dir.
        (and (cdr dired-subdir-alist)
             (dired-goto-subdir up))
        (progn
          (if other-window
              (dired-other-window up)
            (progn
              (kill-buffer (current-buffer))
              (dired up))
          (dired-goto-file dir))))))

(define-key dired-mode-map (kbd "M-m") '(lambda () (interactive) (dired-move-to-filename)))
(define-key dired-mode-map (kbd "^") 'dired-my-up-directory)
(define-key dired-mode-map (kbd "RET") 'dired-my-advertised-find-file)
(define-key dired-mode-map (kbd "<left>") 'dired-my-up-directory)
(define-key dired-mode-map (kbd "<right>") 'dired-my-advertised-find-file)
;;; 2011-05-11 (Wed)
;;; C-t が image-なんたら の prefix で潰れているので unset
(define-key dired-mode-map (kbd "C-t") nil)
;;--------------------------------------------------------
;;; Dired で Windows に関連付けられたファイルを起動する。
;;; http://www.bookshelf.jp/soft/meadow_25.html
;;--------------------------------------------------------
(defun my-dired-start ()
  "Type '\\[my-dired-start]': start the current line's file."
  (interactive)
  (when (eq major-mode 'dired-mode)
      (let ((fname (dired-get-filename))
            (coding-system-for-read 'utf-8-unix)     ; この2行がないと日本語名の
            (coding-system-for-write 'utf-8-unix))   ; ファイルが開けないので設定しとく
        (cond ((winp) (w32-shell-execute "open" fname))
              ((linuxp) (call-process-shell-command "gnome-open" nil nil nil fname)))
        (message "started %s" fname))))
(add-hook 'dired-mode-hook
          (lambda ()
            (define-key dired-mode-map "z" 'my-dired-start))) ;;; 関連付け
;; スペースでマークする (FD like)
(defun dired-toggle-mark (arg)
  "Toggle the current (or next ARG) files."
  ;; S.Namba Sat Aug 10 12:20:36 1996
  (interactive "P")
  (let ((dired-marker-char
         (if (save-excursion (beginning-of-line)
                             (looking-at " "))
             dired-marker-char ?\040)))
    (dired-mark arg)
    (dired-previous-line 1)))
(define-key dired-mode-map (kbd "SPC") 'dired-toggle-mark)
;; (auto-install-from-emacswiki "dired-isearch.el")
;; ファイル名のみで isearch
(setq dired-isearch-filenames 'dwim)        ; dired-aux で定義されている．これだけで十分だった
;; (my-safe-require 'dired-isearch
;;   (define-key dired-mode-map (kbd "C-s") 'dired-isearch-forward)
;;   (define-key dired-mode-map (kbd "C-r") 'dired-isearch-backward)
;;   (define-key dired-mode-map (kbd "ESC C-s") 'dired-isearch-forward-regexp)
;;   (define-key dired-mode-map (kbd "ESC C-r") 'dired-isearch-backward-regexp)
;;   )

;; dired バッファは折り返さない
(add-hook 'dired-mode-hook
          (lambda ()
            (toggle-truncate-lines 1)))

;;; 2011-08-08 (Mon)
;;; dired ですべてのファイルにマークしたり
(defun dired-my-mark-all-files ()
  "Mark all files in a current dired buffer."
  (interactive)
  (dired-mark-files-regexp ""))

(defun dired-my-get-number-of-marked-files ()
  "Get the number of marked files."
  (interactive)
  (let ((case-fold-search nil)
        (mark-regexp "^\\*\\|^D")
        (count 0))
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward mark-regexp nil t)
        (setq count (1+ count))))
    count))

(defadvice dired-unmark-all-marks (around dired-my-mark-all-marks-dwim activate)
  "Mark all files or unmark all marks."
  (if (> (dired-my-get-number-of-marked-files) 0)
      ad-do-it
      (dired-my-mark-all-files)))
(define-key dired-mode-map (kbd "U") 'dired-unmark-all-marks)

;;; dired で文字コード一括変換
;;; http://www.bookshelf.jp/soft/meadow_25.html#SEC278
(defvar dired-default-file-coding-system nil
  "*Default coding system for converting file (s).")

(defvar dired-file-coding-system 'no-conversion)

(defun dired-convert-coding-system ()
  (let ((file (dired-get-filename))
        (coding-system-for-write dired-file-coding-system)
        failure)
    (condition-case err
        (with-temp-buffer
          (insert-file file)
          (write-region (point-min) (point-max) file))
      (error (setq failure err)))
    (if (not failure)
        nil
      (dired-log "convert coding system error for %s:\n%s\n" file failure)
      (dired-make-relative file))))

(defun dired-do-convert-coding-system (coding-system &optional arg)
  "Convert file (s) in specified coding system."
  (interactive
   (list (let ((default (or dired-default-file-coding-system
                            buffer-file-coding-system)))
           (read-coding-system
            (format "Coding system for converting file (s) (default, %s): "
                    default)
            default))
         current-prefix-arg))
  (check-coding-system coding-system)
  (setq dired-file-coding-system coding-system)
  (dired-map-over-marks-check
   (function dired-convert-coding-system) arg 'convert-coding-system t))
(define-key dired-mode-map (kbd "F") 'dired-do-convert-coding-system)

;;; dired-details.el
;;; 2011-07-19 (Tue)
;;; dired のファイル情報の詳細表示をトグルする
;;; (auto-install-from-emacswiki "dired-details.el")
;;; (auto-install-from-emacswiki "dired-details+.el")
(my-safe-require 'dired-details+
  (setq dired-details-hidden-string "")
  (setq dired-details-hide-link-targets nil)
  )

(defun anything-dired-file ()
  "Anything command in dired buffer."
  (interactive)
  (anything-other-buffer
   '(anything-c-source-files-in-current-dir+)
   "*anything dired:"))
(define-key dired-mode-map (kbd "/") 'anything-dired-file)

;;; generic-x.el
;;; 2011-03-07 (Mon)
;;; 予め定義されている generic
(my-safe-require 'generic-x)

;;; filecache.el
;;; 2011-02-21 (Mon)
;;; よく開くファイルやディレクトリをキャッシュとして保存しておく
;;; find-file の時に C-TAB で補完できる
(my-safe-require 'filecache
  ;; キャッシュするディレクトリを指定。このディレクトリ下のファイルを補完できる
  ;; ディレクトリは対象外らしい
  (file-cache-add-directory-list
   (list "~/.emacs.d/" "~/.emacs.d/auto-install/" "~/.emacs.d/site-lisp")))

;;; skk
;; (setq skk-user-directory "~/.emacs.d/ddskk/")
;; (when (require 'skk-autoloads nil t)
;;   (define-key global-map (kbd "C-x C-j") 'skk-mode)
;;   (setq skk-byte-compile-init-file t))

;;; desktop.el
;;; 2010-11-25 (Thu)
;;; EmacsWiki より
;;; セッションのバッファの状態を保存する(次回起動時に勝手にファイルを開いてくれる)
;;; 保存しないファイルの正規表現
(my-safe-require 'desktop
  (setq desktop-files-not-to-save "\\(^/[^/:]*:\\|\\.diary\\'\\)")
  (run-at-time t 60 'desktop-save "~/") ; 定期的にdesktop を保存する
  (desktop-save-mode t))

;;; uniquify.el
;;; 2010-11-06 (Sat)
;;; Emacsテクニックバイブル より
;;; ファイル名がかぶったときわかり易くする
(my-safe-require 'uniquify
  ;; filename<dir> 形式のバッファ名にする
  (setq uniquify-buffer-name-style 'post-forward-angle-brackets)
  ;; *で囲まれたバッファ名は対象外にする
  (setq uniquify-ignore-buffers-re "*[^*]+*"))

;;; iswitchb.el
;;; 2010-11-06 (Sat)
;;; Emacsテクニックバイブル より
;;; バッファ切り替えを強化する
;; (iswitchb-mode 1)
;; ;; バッファ読み取り関数を iswitchb にする
;; (setq read-buffer-function 'iswitchb-read-buffer)
;; ;; 部分文字列の代わりに正規表現を使う場合は t に設定する
;; (setq iswitchb-regexp t)
;; ;; 新しいバッファを作成するときにいちいち聞いてこない
;; (setq iswitchb-prompt-newbuffer nil)

(my-measure-message-time "Standard elisp setting.")
;;;;;;;;;;;;;;;; 非標準elisp ;;;;;;;;;;;;;;;;
;;; expand-region.el
;;; https://github.com/magnars/expand-region.el
(my-safe-require 'expand-region
  ;; (define-key global-map (kbd "M-@") 'er/expand-region)
  (define-key global-map (kbd "C-@") 'er/expand-region))

;;; auto-save-buffers.el
;;; アイドル時に自動保存
;;; (auto-install-from-url "http://homepage3.nifty.com/oatu/emacs/archives/auto-save-buffers.el")
(my-safe-require 'auto-save-buffers
  (run-with-idle-timer 2 t 'auto-save-buffers))

;;; smartrep.el
;;; 連続入力を支援
;;; http://sheephead.homelinux.org/2011/12/19/6930/ Marmalade よりインストール
(my-safe-require 'smartrep

  (smartrep-define-key
   global-map "C-x" '(("{" . (lambda () (enlarge-window-horizontally -1)))
                      ("}" . (lambda () (enlarge-window-horizontally 1)))))

  (define-key global-map (kbd "C-M-v") nil)
  (smartrep-define-key
   global-map "C-M-v" '(("j" . (lambda () (scroll-other-window 1)))
                        ("k" . (lambda () (scroll-other-window -1)))
                        ("J" . (lambda () (scroll-other-window 4)))
                        ("K" . (lambda () (scroll-other-window -4)))
                        ("d" . (lambda () (scroll-other-window (/ (window-height) 2))))
                        ("u" . (lambda () (scroll-other-window (- (/ (window-height) 2)))))
                        ("f" . 'scroll-other-window)
                        ("b" . (lambda () (scroll-other-window '-)))
                        ("g" . (lambda () (beginning-of-buffer-other-window 0)))
                        ("G" . (lambda () (end-of-buffer-other-window 0)))))

  (eval-after-load "org"
    '(progn
       (smartrep-define-key
        org-mode-map "C-c" '(("C-n" . (lambda ()
                                        (outline-next-visible-heading 1)))
                             ("C-p" . (lambda ()
                                        (outline-previous-visible-heading 1)))
                             ("C-f" . (lambda ()
                                        (org-forward-same-level 1)))
                             ("C-b" . (lambda ()
                                        (org-backward-same-level 1)))))
       ))

  (eval-after-load "yatex"
    '(progn
       (smartrep-define-key
        YaTeX-mode-map "C-c" '(("C-n" . (lambda ()
                                          (outline-next-visible-heading 1)))
                               ("C-p" . (lambda ()
                                          (outline-previous-visible-heading 1)))))
       ))
  )


;;; quickrun.el
;;; ワンタッチでスクリプト実行
;;; (auto-install-from-url "https://raw.github.com/syohex/emacs-quickrun/master/quickrun.el")
(my-safe-require 'quickrun
  (define-key global-map (kbd "<f8>") 'quickrun)
  )

;;; cycle-buffer.el
;;; バッファを環状に訪問
;;; (auto-install-from-emacswiki "cycle-buffer.el")
(my-safe-require 'cycle-buffer
  (define-key global-map (kbd "C-.") 'cycle-buffer)
  (define-key global-map (kbd "C-,") 'cycle-buffer-backward)
  )

;;; anything-advent-calendar.el
;;; advent calendar を anything で選んで閲覧
;;; http://gongo.hatenablog.com/entry/2011/12/12/000301
(my-safe-require 'anything-advent-calendar)

;;; sunrise-commander.el
;;; 2ペインファイラー？
;;; installed by package.el from "SC"
(my-safe-require 'sunrise-commander)

;;; shell-history.el
;;; シェルの履歴を履歴ファイルに書きこむ
;;; (auto-install-from-url "http://www.emacswiki.org/cgi-bin/wiki/download/shell-history.el")
(my-safe-require 'shell-history
  (setq shell-history-file "~/.zsh_history")

  ;; add command in shell-mode to history file
  (defadvice comint-send-input (before add-to-shell-history activate)
    (when (eq major-mode 'shell-mode)
      (add-to-shell-history (buffer-substring (point-at-bol) (point-at-eol)))))
  )

;;; cedet.el
;;; Emacs で開発環境
;;; http://cedet.sourceforge.net/
;; (my-safe-load (expand-file-name "repo/cedet-1.0/common/cedet.el" dropbox-directory)
;;   (global-ede-mode 1)                      ; Enable the Project management system
;;   (semantic-load-enable-code-helpers)      ; Enable prototype help and smart completion
;;   (global-srecode-minor-mode 1)            ; Enable template insertion menu
;;   )

;;; open-junk-file.el
;;; 試行錯誤用ファイルを開く
;;; (auto-install-from-emacswiki "open-junk-file.el")
(my-safe-require 'open-junk-file
  (setq open-junk-file-format
        (expand-file-name "junk/%Y/%m/%d-%H%M%S-junk." user-emacs-directory))
  (define-key ctl-x-map (kbd "C-j") 'open-junk-file)
  )

;;; lispxmp.el
;;; 式の評価結果を注釈する
;;; (auto-install-from-emacswiki "lispxmp.el")
(my-safe-require 'lispxmp
  (define-key emacs-lisp-mode-map (kbd "C-c C-d") 'lispxmp)
  )

;;; paredit.el
;;; 括弧の対応を保持して編集
;;; (auto-install-from-url "http://mumble.net/~campbell/emacs/paredit.el")
;; (my-safe-require 'paredit
;;   (add-hook 'emacs-lisp-mode-hook 'enable-paredit-mode)
;;   (add-hook 'lisp-interaction-mode-hook 'enable-paredit-mode)
;;   (add-hook 'lisp-mode-hook 'enable-paredit-mode)
;;   (add-hook 'ielm-mode-hook 'enable-paredit-mode)
;;   )
;; paredit.el をつけておくとファイルを開くときにメジャーモードの判定に
;; 失敗したりする．何でかは分からんが不便なのでコメントアウトしとく

;;; undo-tree.el
;;; 編集履歴を木構造で視覚的に表示しアンドゥできる
;;; http://www.dr-qubit.org/emacs.php
(my-safe-require 'undo-tree
  (global-undo-tree-mode)
  (setq-default undo-tree-visualizer-timestamps t) ; display timestamp in visualizer
  ;(define-key undo-tree-map (kbd "C-g") 'undo-tree-visualizer-quit)  ; unable to bind "C-g"?
  ;; bind redo to "C-_" because default bind "C-?" is unavailable in CUI
  ;(define-key undo-tree-map (kbd "C-_") 'undo-tree-redo)
  ;; "C-/" is translated "C-_" in CUI. So, I can't use undo-tree-undo on above setting.
  )

;;; egg.el
;;; git クライアント
;;; https://github.com/bogolisk/egg
;(my-safe-require 'egg)

;;; keywiz.el
;;; コマンドが割り当てられているキーバインドを答えるクイズ．
(my-safe-require 'keywiz)

;;; highlight-80+.el
;;; 指定したカラムを超えているテキストに色付けする
;;; 日本語の考慮なし．やっぱ自分でつくるしかないか．
(my-safe-require 'highlight-80+
  (setq highlight-80+-columns fill-column))

;;; ya-hatena-mode.el
;;; Emacs からはてなダイアリーに投稿する
;;; https://github.com/takaishi/ya-hatena-mode
(setq *yhtn:account-info-file* "~/.yhtn-account-info.el") ; デフォルトは .yhtn:account-~~~ だが Ubuntu 環境だと
                                                          ; そのファイル名が認識できない？のかロードできない
(when (file-exists-p *yhtn:account-info-file*)
  (my-safe-require 'ya-hatena-mode
    ;; key bind
    (define-key ya-hatena-mode-map "\C-cp" nil)
    (define-key ya-hatena-mode-map "\C-cd" nil)
    (define-key ya-hatena-mode-map "\C-cq" nil)
    (define-key ya-hatena-mode-map "\C-cm" nil)
    (define-key ya-hatena-mode-map (kbd "C-c C-p") 'yhtn:d:post-blog-collection-buffer)
    (define-key ya-hatena-mode-map (kbd "C-c C-d") 'yhtn:d:post-draft-collection-buffer)
    (define-key ya-hatena-mode-map (kbd "C-c C-q") 'yhtn:d:quit)
    (define-key ya-hatena-mode-map (kbd "C-c C-m") 'yhtn:d:action)
    ))

;;; marmalade.el
;;; パッケージ管理サーバ（http://marmalade-repo.org/）とのやりとりをする
(my-safe-load "marmalade")

;;; kogiku.el
;;; http://kogiku.sourceforge.jp/
;; (my-safe-require 'kogiku
;;   (setq kogiku-enable-once nil))

;;; nyan-mode.el
;;; (auto-install-from-url "https://raw.github.com/TeMPOraL/nyan-mode/master/nyan-mode.el")
(my-safe-require 'nyan-mode)

;;; typing.el
;;; (auto-install-from-emacswiki "typing.el")
(autoload 'typing-of-emacs "typing" "The Typing Of Emacs, a game." t)

;;; e2wm-vcs.el
;;; (auto-install-from-url "http://svn.apache.org/repos/asf/subversion/trunk/contrib/client-side/emacs/dsvn.el")
;;; (auto-install-from-url "https://github.com/kiwanami/emacs-window-manager/raw/master/e2wm-vcs.el")
;;; e2wm で magit を操作するパースペクティブ
;;; http://d.hatena.ne.jp/kiwanami/20110702/1309592243
; (my-safe-require 'e2wm-vcs)
;; あまりうまく動いてない気がする．まあそのままの magit でいいか

;;; simple-hatena-mode.el
;;; 2011-07-17 (Sun)
;;; (auto-install-from-url "http://tuvalu.santafe.edu/~nelson/tools/html-helper-mode.el")
;;; (auto-install-from-url "http://svn.coderepos.org/share/lang/elisp/simple-hatena-mode/tags/release-0.15/simple-hatena-mode.el")
;;; はてな編集用のメジャーモード．投稿機能あり．
(my-safe-require 'simple-hatena-mode
  (my-safe-require 'html-helper-mode)
  (setq simple-hatena-bin "hw.pl")
  (setq simple-hatena-default-id "kbkbkbkb1"))

;;; judge-indent.el
;;; 2011-06-27 (Mon)
;;; (auto-install-from-url "https://raw.github.com/yascentur/judge-indent-el/1.0.0/judge-indent.el")
;;; http://d.hatena.ne.jp/yascentur/20110626/1309099966
;;; インデントの幅やタブを操作，モードラインに表示
(my-safe-require 'judge-indent
  (global-judge-indent-mode t)
  (setq judge-indent-major-modes '(c-mode python-mode sh-mode)))

;;; longlines-jp.el
;;; 2011-06-23 (Thu)
;;; 長い行の仮想折り返し，日本語バージョン
;;; (auto-install-from-emacswiki "longlines-jp.el")
(my-safe-require 'longlines-jp
  (setq longlines-jp-show-effect (propertize "\\n\n" 'face 'font-lock-keyword-face))
  (setq longlines-jp-show-hard-newlines t)
  (define-key my-original-map (kbd "C-j") 'longlines-jp-mode)
  )

;;; jaspace.el
;;; 2011-06-23 (Thu)
;;; 全角空白を明示する
;;; (auto-install-from-url "http://homepage3.nifty.com/satomii/software/jaspace.el")
;; (my-safe-require 'jaspace
;;   (setq jaspace-alternate-jaspace-string nil) ; Ricty で全角空白はわかるので nil にする．
;;   (setq jaspace-alternate-eol-string "\xab\n"))
;; やっぱ常に改行文字はうざかった

;;; thing-opt.el
;;; 2011-06-22 (Wed)
;;; thing を定義，操作する
;;; (auto-install-from-url "http://www.emacswiki.org/emacs/download/thing-opt.el")
;;; http://dev.ariel-networks.com/articles/emacs/part5/
(my-safe-require 'thing-opt
  (define-thing-commands)
  (eval-after-load "key-chord"
    '(progn
       (key-chord-define-global "dw" 'kill-word*)
       (key-chord-define-global "yw" 'copy-word)
       (key-chord-define-global "vw" 'mark-word*)
       (key-chord-define-global "ds" 'kill-sexp*)
       (key-chord-define-global "ys" 'copy-sexp)
       (key-chord-define-global "vs" 'mark-sexp*)
       (key-chord-define-global "dq" 'kill-string)
       (key-chord-define-global "yq" 'copy-string)
       (key-chord-define-global "vq" 'mark-string)
       (key-chord-define-global "dl" 'kill-up-list)
       (key-chord-define-global "yl" 'copy-up-list)
       (key-chord-define-global "vl" 'mark-up-list)))
  )

;;; nav.el
;;; 2011-06-05 (Sun)
;;; http://code.google.com/p/emacs-nav/
;;; ディレクトリのファイル一覧を表示
(my-safe-require 'nav)

;;; bookmark-extensions.el
;;; 2011-06-05 (Sun)
;;; bookmark.el の拡張
;;; (auto-install-from-url "http://mercurial.intuxication.org/hg/emacs-bookmark-extension/raw-file/7a874534bc63/bookmark-extensions.el")
;;; anything-bookmark-ext に必要なようだ．多少はブックマークが使いやすくなるのか？
;(my-safe-require 'bookmark-extensions)
;; 使い方がよう分からん

;;; e2wm.el
;;; 2011-05-31 (Tue)
;;; IDE 的なウィンドウ管理とか
;;; (auto-install-from-url "http://github.com/kiwanami/emacs-window-layout/raw/master/window-layout.el")
;;; (auto-install-from-url "http://github.com/kiwanami/emacs-window-manager/raw/master/e2wm.el")
;; (my-safe-require 'e2wm
;;   (define-key global-map (kbd "M-+") 'e2wm:start-management)
;;   )
;; うーん，ほかの elisp との競合が多そう．使わないほうがいいかなぁ

;;; magit.el
;;; 2011-05-28 (Sat)
;;; emacs から git を操作
(my-safe-require 'magit
  ;; 日本語のエンコーディングを utf-8 にする．デフォルトではマルチバイト文字が考慮されていないようで
  ;; なにも設定されていないので文字化けしてしまう．
  (add-to-list 'process-coding-system-alist (cons magit-git-executable 'utf-8))
  ;; face color
  (set-face-foreground 'magit-diff-add "green")
  (set-face-foreground 'magit-diff-del "red")
  (set-face-foreground 'magit-diff-hunk-header "yellow")
  (set-face-foreground 'magit-diff-file-header "magenta") ; 効果なし？ version をあげたら良くなった
  (set-face-background 'magit-item-highlight "gray20")

  (defun magit-view-item-other-window ()
    "View item in other window."
    (interactive)
    (magit-visit-item t)
    (other-window -1))

  (define-key magit-mode-map (kbd "C-o") 'magit-view-item-other-window)
  ;; (defun my-magit-apply-file-header-face ()
  ;;   "Apply magit-diff-file-header."
  ;;   (interactive)
  ;;   (goto-char (point-min))
  ;;   (while (re-search-forward "^diff --git" nil t)
  ;;     (let ((min-pt (match-beginning 0)))
  ;;       (when (re-search-forward "^\+\+\+.*$" nil t)
  ;;         (add-text-properties min-pt (match-end 0)
  ;;                              '(face magit-diff-file-header))))))
  ;; (add-hook 'magit-mode-hook 'my-magit-apply-file-header-face t)
  ;; あんま上手くいかんねー
  )

;;; col-hilight
;;; 2011-05-22 (Sun)
;;; (auto-install-from-url "http://www.emacswiki.org/cgi-bin/wiki/download/vline.el")
;;; (auto-install-from-url "http://www.emacswiki.org/emacs/download/col-highlight.el")
;;; hilight current column
(my-safe-require 'col-highlight
  ;(column-highlight-mode 1)
  ;; 常に on にしとくのはちょっと重すぎるのでコメントアウト
  (custom-set-faces
   '(col-highlight ((t (:background "gray10")))))
  (setq col-highlight-period 4)
  (define-key global-map (kbd "C-+") 'flash-column-highlight)
  (define-key my-original-map (kbd "C-c") 'column-highlight-mode)
  )

;;; yasnippet.el
(my-safe-require 'yasnippet
  (add-to-list 'auto-mode-alist '("\\.\\(ya\\)?snippet\\'" . snippet-mode))
  ;; キーバインドは以下を参考にした
  ;; http://emacs.g.hatena.ne.jp/Shinnya/20100805/1281034504
  (setq yas/trigger-key (kbd "<C-tab>"))      ; TAB だと auto-complete とかぶるので変更
  (setq yas/next-field-key (kbd "<C-tab>"))   ; これが <C-tab> にならんなぁ
  ;; (setq yas/prev-field-key "<S-tab>")
  ;; (define-key yas/minor-mode-map (kbd "C-<tab>") 'yas/expand)
  (setq yas/wrap-around-region t)
  ;; (defadvice anything-c-yas-complete
  ;;   (around anything-c-yas-complete-delete-region activate)
  ;;   "If region is active, delete region before yasnippet completion."
  ;;   (when mark-active
  ;;     (let ((reg-beg (region-beginning))
  ;;           (reg-end (region-end)))
  ;;       ad-do-it
  ;;       (delete-region reg-beg reg-end))))
  ;(ad-deactivate-regexp "anything-c-yas-complete-delete-region")
  ;; (eval-after-load "auto-complete.el"
  ;;   (define-key ac-complete-mode-map (kbd "<C-tab>") 'yas/expand))
  (yas/initialize)
  (yas/load-directory  "~/.emacs.d/snippets")

  ;; original function
  (defun yas/c-format-count (str)
    "Return comma according to c format string"
    (save-match-data
      (set-match-data nil)
      (let ((result ""))
        (when (string-match "%[^%]" str)
          (setq result ", ")
          (while (string-match "%[^%]" str (match-end 0))
            (setq result (concat result ", "))))
        result)))

  )

;;; cygwin-mount.el
;;; 2011-05-18 (Wed)
;;; (auto-install-from-url "http://home.avvanta.com/~offby1/cygwin-mount/cygwin-mount.el")
;;; cygwin のパスを使えるようにする
;; (when (winp)
;;   (my-safe-require 'cygwin-mount
;;     (cygwin-mount-activate)))
;; 一部しかして欲しくないパスの展開を全部やっちゃうので却下


;;; zlc.el
;;; 2011-05-06 (Fri)
;;; (auto-install-from-url "https://github.com/mooz/emacs-zlc/raw/master/zlc.el")
;;; ミニバッファでの補完を zsh ライクにする
(my-safe-require 'zlc
  (let ((map minibuffer-local-map))
    ;; like menu select
    (define-key map (kbd "<down>")  'zlc-select-next-vertical)
    (define-key map (kbd "<up>")    'zlc-select-previous-vertical)
    (define-key map (kbd "<right>") 'zlc-select-next)
    (define-key map (kbd "<left>")  'zlc-select-previous)

    (define-key map (kbd "H-n")  'zlc-select-next-vertical)
    (define-key map (kbd "H-p")    'zlc-select-previous-vertical)
    (define-key map (kbd "H-f") 'zlc-select-next)
    (define-key map (kbd "H-b")  'zlc-select-previous)
    ))

;;; moz.el
;;; 2011-05-03 (Tue)
;;; (auto-install-from-url "http://github.com/bard/mozrepl/raw/master/chrome/content/moz.el")
;;; mozrepl を通して firefox を操作する
(my-safe-require 'moz
  (defvar moz-scroll-ratio "80") ;; スクロール量の比率。100(%)で1ページ毎のスクロール。
  (defvar moz-scroll-time "15") ;; アニメーション時間。高いほどゆっくりに。

  (defun moz-send-line (str)
    (interactive)
    (comint-send-string (inferior-moz-process)
                        (concat moz-repl-name ".pushenv('printPrompt', 'inputMode'); "
                                moz-repl-name ".setenv('inputMode', 'line'); "
                                moz-repl-name ".setenv('printPrompt', false); undefined; "))
    (comint-send-string (inferior-moz-process) (concat str "; "))
    (comint-send-string (inferior-moz-process)
                        (concat moz-repl-name ".popenv('inputMode', 'printPrompt'); undefined;\n")))
  (defun moz-scroll-down ()
    (interactive)
    (moz-send-line (concat "(function(){var t=" moz-scroll-time ",r=" moz-scroll-ratio " ;var i=0,w =document.documentElement,s=gBrowser.selectedBrowser.contentWindow.scrollY,e=s+w.clientHeight/(100/r),v=(e-s)/t,c=s;for(i;i<t;i++){setTimeout(function(){c+=v;content.scrollTo(0,c);},i+1)}})();")))
  (defun moz-scroll-up ()
    (interactive)
    (moz-send-line (concat "(function(){var t=" moz-scroll-time ",r=" moz-scroll-ratio " ;var i=0,w =document.documentElement,s=gBrowser.selectedBrowser.contentWindow.scrollY,e=s+w.clientHeight/(100/r),v=(e-s)/t,c=s;for(i;i<t;i++){setTimeout(function(){c-=v;content.scrollTo(0,c);},i+1)}})();")))
  (defun moz-prev-tab ()
    (interactive)
    (moz-send-line "gBrowser.mTabContainer.advanceSelectedTab(-1, true)"))
  (defun moz-next-tab ()
    (interactive)
    (moz-send-line "gBrowser.mTabContainer.advanceSelectedTab(1, true)"))

  (define-key my-original-map (kbd "b") 'moz-scroll-up)
  (define-key my-original-map (kbd "f") 'moz-scroll-down)
  (define-key my-original-map (kbd "h") 'moz-prev-tab)
  (define-key my-original-map (kbd "l") 'moz-next-tab)

  ;; http://blogs.openaether.org/?p=236
  (defun jk/moz-get (attr)
    (comint-send-string (inferior-moz-process) attr)
    ;; try to give the repl a chance to respond
    (sleep-for 0 100))
  (defun jk/moz-get-current-url ()
    (interactive)
    (jk/moz-get "repl._workContext.content.location.href"))
  (defun jk/moz-get-current-title ()
    (interactive)
    (jk/moz-get "repl._workContext.content.document.title"))
  (defun jk/moz-get-current (moz-fun)
    (funcall moz-fun)
    ;; doesn't work if repl takes too long to output string
    (save-excursion
      (set-buffer (process-buffer (inferior-moz-process)))
      (goto-char (point-max))
      (previous-line)
      (setq jk/moz-current (buffer-substring-no-properties
                            (+ (point-at-bol) (length moz-repl-name) 3)
                            (- (point-at-eol) 1))))
    (message "%s" jk/moz-current)
    jk/moz-current)
  (defun jk/moz-url ()
    (interactive)
    (jk/moz-get-current 'jk/moz-get-current-url))
  (defun jk/moz-title ()
    (interactive)
    (jk/moz-get-current 'jk/moz-get-current-title))
  ;; Firefox のページを emacs-w3m で開く
  (defun jk/moz-url-w3m ()
    "Open current page of Firefox on emacs-w3m."
    (interactive)
    (w3m-browse-url (jk/moz-url)))

  )


;;; anything-books.el
;;; 2011-04-21 (Thu)
;;; (auto-install-from-url "https://github.com/kiwanami/emacs-anything-books/raw/master/anything-books.el")
;;; anything で本管理
(my-safe-require 'anything-books
  (setq abks:books-dir (concat dropbox-directory "/document")) ; PDFファイルのあるディレクトリ（★必須）
  (setq abks:open-command "acroread") ; LinuxのAdobeReaderを使う (default)

  ;; for evince setting (default)
  ;; (setq abks:cache-pixel "600")
  ;; (setq abks:mkcover-cmd-pdf-postfix nil)
  ;; (setq abks:mkcover-cmd '("evince-thumbnailer" "-s" size pdf jpeg))

  ;; for ImageMagick and GhostScript setting
  (setq abks:cache-pixel "600x600")
  (setq abks:mkcover-cmd-pdf-postfix "[0]")
  (setq abks:mkcover-cmd '("convert" "-resize" size pdf jpeg))

  ;(define-key mode-specific-map (kbd "b") 'anything-books-command) ; キーバインド
  (setq abks:cmd-copy "cp") ; ファイルコピーのコマンド
  (setq abks:copy-by-command nil) ; nilにするとEmacsの機能でコピーする（Windowsはnilがいいかも）
  (setq abks:preview-temp-dir "/tmp") ; 作業ディレクトリ
  )
;; うまく動かんので、とりあえず Ubuntu でやってみよう
;; Ubuntu でもほぼ同じ症状のようだ。
;; とりあえず、一部の pdf しかリストに表示されない。プレビュー自体は
;; 問題ないようだ。

;;; concurrent.el
;;; 非同期処理フレームワーク
;;; (auto-install-from-url "https://github.com/kiwanami/emacs-deferred/raw/master/concurrent.el")
(my-safe-require'concurrent)

;;; deferred.el
;;; 2011-04-21 (Thu)
;;; (auto-install-from-url "http://github.com/kiwanami/emacs-deferred/raw/master/deferred.el")
;;; 非同期処理ライブラリ
(my-safe-require 'deferred)

;;; anything.el
;;; 2011-04-21 (Thu)
;;; (auto-install-batch "anything")
;;; 1つでなんでもできる，汎用インターフェース
(my-safe-require 'anything-startup
  (when (executable-find "cmigemo")
    (my-safe-require 'anything-migemo))

  (define-key global-map (kbd "C-S-a") 'anything-command-map)
  (add-to-list 'anything-c-source-recentf '(migemo)) ; migemo 化
  (add-to-list 'anything-c-source-buffers+ '(migemo))

  ;; for filelist
  ;; (when (linuxp)
  ;;   (setq anything-grep-candidates-fast-directory-regexp "^/tmp")
  ;;   (setq anything-c-filelist-file-name "/tmp/all.filelist"))
  ;; どうも grep 上手くいかない．all.filelist が大きすぎか？
  ;; よし，linux なら locate 使えるので anything-for-files でいいか．current-dir+ も候補に入るし
  (define-key mode-specific-map (kbd "r") 'anything-for-files) ; recentfile 的に使いたい

  ;; anything-show-kill-ring
  (define-key global-map (kbd "M-y") 'anything-show-kill-ring)
  (setq anything-kill-ring-threshold 4) ; this variable defines minimum length of strings to show

  ;;;; external elisp

  ;;; anything-orgcard.el
  ;;; (auto-install-from-url "https://raw.github.com/gist/1345100/332610ed43c0c310be3281280285fc41b3d4cbdd/anything-orgcard.el")
  ;;; Org-mode のリファレンスカードを使って機能検索 http://d.hatena.ne.jp/kiwanami/20111109/1320857773
  (my-safe-require 'anything-orgcard)
  )

;;; anything-c-yasnippet.el
;;; (auto-install-from-url "http://svn.coderepos.org/share/lang/elisp/anything-c-yasnippet/anything-c-yasnippet.el")
;;; yasnippet を anything で操作
(my-safe-require 'anything-c-yasnippet
  (setq anything-c-yas-space-match-any-greedy t) ; スペース区切りで絞り込めるようにする デフォルトは nil
  (global-set-key (kbd "C-c y") 'anything-c-yas-complete) ; C-c yで起動 (同時にお使いのマイナーモードとキーバインドがかぶるかもしれません)
  )

;;; Inertial-scroll.el
;;; 2011-04-21 (Thu)
;;; (auto-install-from-url "http://github.com/kiwanami/emacs-inertial-scroll/raw/master/inertial-scroll.el")
;;; http://d.hatena.ne.jp/kiwanami/20101008/1286518936 より
;;; 慣性スクロール
;; (my-safe-require 'inertial-scroll
;;   (setq inertias-global-minor-mode-map
;;         (inertias-define-keymap
;;          '(
;;            ("<wheel-up>"   . inertias-down-wheel)
;;            ("<wheel-down>" . inertias-up-wheel)
;;            ("<mouse-4>"    . inertias-down-wheel)
;;            ("<mouse-5>"    . inertias-up-wheel)
;;            ("<next>"  . inertias-up)
;;            ("<prior>" . inertias-down)
;;            ("C-v"     . inertias-up)
;;            ("M-v"     . inertias-down)
;;            ) inertias-prefix-key))
;;   (inertias-global-minor-mode 1)
;;   (setq inertias-initial-velocity 90) ; 初速（大きいほど一気にスクロールする）
;;   (setq inertias-initial-velocity-wheel 50) ; ホイールの初速（大きいほど一気にスクロールする）
;;   (setq inertias-friction 200)        ; 摩擦抵抗（大きいほどすぐ止まる）
;;   (setq inertias-rest-coef 0)         ; 画面端でのバウンド量（0はバウンドしない。1.0で弾性反発）
;;   (setq inertias-update-time 1)      ; 画面描画のwait時間（msec）
;;   )
;; 見た目はおもろいし、わかりやすくなる。しかし、スクロールするのに多少の時間がかかるので、常用するのは微妙かもしれん。

;;; smartchr.el
;;; 2011-04-18 (Mon)
;;; (auto-install-from-url "https://github.com/imakado/emacs-smartchr/raw/master/smartchr.el")
;;; 1つのキーに様々な文字列を割り当てることができる
;; (my-safe-require 'smartchr
;;   (define-key global-map (kbd "=") (smartchr '(" = " " == " "=")))
;;   (define-key global-map (kbd "{") (smartchr '("{`!!'}" "{")))
;;   (define-key global-map (kbd "(") (smartchr '("(`!!')" "(")))
;;   )
;; 若干使いにくい。プログラミングの時だけ有効とかにしたほうがいいか

;;; switch-window.el
;;; 2011-04-18 (Mon)
;;; (auto-install-from-url "https://github.com/dimitri/switch-window/raw/master/switch-window.el")
;;; ウィンドウの移動を番号で指定して移動する
(my-safe-require 'switch-window)
;; C-x o の代替としてはまあまあいいかもしれない

;;; hatena-diary-mode.el
;;; 2011-04-15 (Fri)
;;; http://hatena-diary-el.sourceforge.jp/
;;; はてなダイアリーを編集、投稿するメジャーモード
(my-safe-require 'hatena-diary-mode
  (setq hatena-usrid "kbkbkbkb1")
  (setq hatena-twitter-flag t)
  (setq hatena-change-day-offset 0)
  (setq hatena-default-coding-system 'utf-8-unix)
  )
;; simple-hatena-mode のほうが良さそう．ただし，simple-hatena には web から日記を
;; ダウンロードする機能がないので，そのために hatena-diary の方を残しておく．

;;; hatenahelper-mode.el
;;; 2011-04-15 (Fri)
;;; http://d.hatena.ne.jp/amt/20060115/HatenaHelperMode
;;; はてなダイアリーの編集を支援するマイナーモード
(my-safe-require 'hatenahelper-mode
  (add-hook 'hatena-diary-mode-hook
            '(lambda ()
               (hatenahelper-mode 1))))

;;; matlab-eldoc.el
;;; 2011-04-15 (Fri)
;;; http://d.hatena.ne.jp/uhiaha888/20101108/1289223580
;;; matlab の引数を表示
(my-safe-require 'matlab-eldoc)

;;; sdic.el
;;; 2011-04-13 (Wed)
;;; 辞書をひく
;; (autoload 'sdic-describe-word
;;   "sdic" "英単語の意味を調べる" t nil)
;; (define-key global-map  (kbd "C-c d") 'sdic-describe-word)
;; (autoload 'sdic-describe-word-at-point
;;   "sdic" "カーソルの位置の英単語の意味を調べる" t nil)
;; (define-key global-map (kbd "C-c D") 'sdic-describe-word-at-point)
;; ;; 英和検索で使用する辞書
;; (setq sdic-eiwa-dictionary-list
;;       '((sdicf-client "~/.emacs.d/dict/gene.sdic")))
;; ;; 和英検索で使用する辞書
;; (setq sdic-waei-dictionary-list
;;       '((sdicf-client "~/.emacs.d/dict/jedict.sdic")))
;; ;; 文字色
;; (setq sdic-face-color "pink")


;;; navi2ch.el
;;; 2011-04-11 (Mon)
(autoload 'navi2ch "navi2ch" "Navigator for 2ch for Emacs" t)
(eval-after-load "navi2ch"
  (progn
    (defadvice navi2ch-article-next-message (after recenter-after activate)
      (recenter))
    (defadvice navi2ch-article-previous-message (after recenter-after activate)
      (recenter)))
  )


;;; color-moccur.el
;;; 2011-04-11 (Mon)
;;; (auto-install-from-url "http://www.bookshelf.jp/elc/color-moccur.el")
;;; 強化版 occur。moccur をもとに改造したらしい。
(my-safe-require 'color-moccur
  (when (executable-find "cmigemo")
    (setq moccur-use-migemo t))           ; 検索に migemo を使う
  (setq moccur-split-word t)              ; 複数の単語で検索できる
  (define-key mode-specific-map (kbd "o") 'occur-by-moccur)
  ; moccur-edit
  ; (auto-install-from-url "http://www.bookshelf.jp/elc/moccur-edit.el")
  (my-safe-load "moccur-edit"))

;;; xdoc2txt.el
;;; http://www.bookshelf.jp/soft/meadow_23.html#SEC238 より
;;; pdf や word のテキスト部分を抽出して表示する
;; (when (winp)
;;   (my-safe-load "xdoc2txt.el"))
;; Windows 専用

;;; mcomplete.el
;;; 2011-04-07 (Thu)
;;; (auto-install-from-url "http://homepage1.nifty.com/bmonkey/emacs/elisp/mcomplete.el")
(my-safe-require 'mcomplete
  (turn-on-mcomplete-mode))

;;; popup-kill-ring.el
;;; 2011-04-07 (Thu)
;;; (auto-install-from-emacswiki "pos-tip.el")
;;; (auto-install-from-emacswiki "popup-kill-ring.el")
;;; キルリングをポップアップで表示
;; (my-safe-require 'popup)
;; (when (null window-system)
;;   (my-safe-require 'pos-tip))           ; terminal のときは pos-tip は使えないため．
;; (my-safe-require 'popup-kill-ring
;;   (global-set-key "\M-y" 'popup-kill-ring)
;;   (setq pos-tip-background-color "red")
;;   (setq popup-kill-ring-item-size-max 2000) ; サイズが 2000 以上の項目については、2000 までに切り捨てる。
;;   (setq popup-kill-ring-timeout 0.1)        ; tooltip 表示までの delay
;;   ;; Windows でも tooltip を表示するように defadvice
;;   ;; Windows の時の window-system が考慮されていなかったのでそれを追加しただけ。
;;   (defadvice popup-kill-ring-pos-tip-show (after popup-kill-ring-pos-tip-show-on-windows activate)
;;     (when (eq window-system 'w32)
;;       (pos-tip-show str popup-kill-ring-pos-tip-color pos nil 0 nil nil nil 0)))
;;   ;; M-n, M-p で候補選択
;;   (define-key popup-kill-ring-keymap (kbd "M-n") 'popup-kill-ring-next)
;;   (define-key popup-kill-ring-keymap (kbd "M-p") 'popup-kill-ring-previous)
;;   ;; yank の直後の場合は yank した文字列を消す
;;   (defadvice popup-kill-ring (before popup-kill-ring-after-yank activate)
;;     (when (eq last-command 'yank)
;;       (undo)))     ; undo はすこし安直すぎるかもしれない
;; )
;; これの代わりに anything-show-kill-ring を使うことにした

;;; drill-instructor.el
;;; (auto-install-from-emacswiki "drill-instructor.el")
;;; Emacs キーバインドを強制
;; (my-safe-require 'drill-instructor)
;; (setq drill-instructor-global t)
;; やっぱやめた

;;; yahtml.el
;;; html 編集モード
(my-safe-require 'yahtml
  (setq auto-mode-alist
        (cons (cons "\\.html$" 'yahtml-mode) auto-mode-alist))
  (autoload 'yahtml-mode "yahtml" "Yet Another HTML mode" t)
  ;(setq yahtml-kanji-code 4)   ; setq で設定すると utf-8 で保存できない．defvar の時点で 4 にしとくといいけどなんでやねん．
  (setq yahtml-www-browser "firefox"))

;;; htmlize.el
;;; Emacs のハイライトをそのまま html に変換
(my-safe-load "htmlize")

;;; approx-search.el
;;; 2011-02-12 (Sat)
;;; http://www.geocities.co.jp/SiliconValley-PaloAlto/7043/#approx-search.el
;;; 曖昧検索できる
;; (my-safe-require 'approx-search
;;   (if (boundp 'isearch-search-fun-function)
;;       (my-safe-require 'approx-isearch)
;;     (my-safe-require 'approx-old-isearch))
;;   (approx-isearch-set-enable))
;; Migemo との共存がちょっとめんどいので一旦コメントアウト

;;; sr-speedbar.el
;;; 2011-02-12 (Sat)
;;; (auto-install-from-emacswiki "sr-speedbar.el")
;;; 同一フレーム内に speedbar を作る
;;; そんなに使い方を理解していない
(my-safe-require 'sr-speedbar
  (define-key global-map (kbd "H-s") 'sr-speedbar-toggle))

;;; cacoo.el
;;; 2011-02-11 (Fri)
;;; http://d.hatena.ne.jp/kiwanami/20110303/1299174459
;;; (auto-install-from-url "https://github.com/kiwanami/emacs-deferred/raw/master/deferred.el")
;;; (auto-install-from-url "https://github.com/kiwanami/emacs-deferred/raw/master/concurrent.el")
;;; (auto-install-from-url "https://github.com/kiwanami/emacs-cacoo/raw/master/cacoo.el")
;;; (auto-install-from-url "https://github.com/kiwanami/emacs-cacoo/raw/master/cacoo-plugins.el")
;;; インライン画像表示 & cacoo編集
(my-safe-require 'cacoo ; cacooを読み込み
  (my-safe-require 'cacoo-plugins)      ; 追加機能
  (setq cacoo:api-key "gZhx0gy6pachw6ZOuWyC") ; ←CacooのAPIキーを入れる（使わない人は無くてもOK）
  ;; 追加設定
  (setq cacoo:img-regexp
        '("\\[img:\\(.*\\)\\][^]\n\r]*$" ; cacoo のデフォルト
          "\\[\\[file:\\([^]\n\r]*\\.\\(jpeg\\|jpg\\|png\\)\\)\\]\\(\\[[^]\n\r]*\\]\\)?\\]" ; org-mode のファイルリンクにマッチさせる
          "\\[\\[\\(http:[^]\n\r]*\\.\\(jpeg\\|jpg\\|png\\)\\)\\]\\(\\[[^]\n\r]*\\]\\)?\\]" ; org-mode の http リンクにマッチさせる
          ))
  (setq cacoo:external-viewer nil)
  (setq cacoo:img-dir (concat user-emacs-directory ".cacoo-cache"))
  (setq cacoo:img-dir-ok t) ; 画像フォルダは確認無しで作る(my-safe-require 'cacoo
  (define-key global-map (kbd "M-c") 'toggle-cacoo-minor-mode)
  (add-to-list 'cacoo:translation-exts "pdf") ; imagemagick で png 形式に変換して表示するファイルの拡張子を登録する
                                              ; デフォルトでは ("ps" "eps" "svg")
  (setq cacoo:png-background "white")
  ;; org-mode のリンクの下線を消す
  ;; http://sheephead.homelinux.org/2011/02/09/6582/
  (defadvice toggle-cacoo-minor-mode
    (around my-toggle-cacoo-minor activate)
    (if (string-equal mode-name "Org")
        (if cacoo-minor-mode
            (progn
              ad-do-it
              (set-face-underline-p 'org-link t))
          (progn
            (set-face-underline-p 'org-link nil)
            ad-do-it))
      ad-do-it))
  ;; 別 prefix を定義する
  (define-prefix-command 'cacoo-my-minor-mode-keymap)
  (setq cacoo-my-map-alist
        '(("q" . cacoo:minor-mode-off-command)
          ("n"   . cacoo:navi-next-diagram-command)
          ("p"   . cacoo:navi-prev-diagram-command)

          ("r"   . cacoo:reload-next-diagram-command)
          ("R"   . cacoo:reload-all-diagrams-command)

          ("g"   . cacoo:reload-or-revert-current-diagram-command)

          ("t"   . cacoo:revert-next-diagram-command)
          ("T"   . cacoo:revert-all-diagrams-command)

          ("d"   . cacoo:display-next-diagram-command)
          ("D"   . cacoo:display-all-diagrams-command)

          ("I"   . cacoo:anything-command)
          ("i"   . cacoo:insert-pattern-command)
          ("y"   . cacoo:insert-yank-command)

          ("N"   . cacoo:create-new-diagram-command)
          ("e"   . cacoo:edit-next-diagram-command)
          ("v"   . cacoo:view-next-diagram-command)
          ("V"   . cacoo:view-local-cache-next-diagram-command)

          ("C"   . cacoo:clear-all-cache-files-command)

          ("l"   . cacoo:open-diagram-list-command)))
  (mapc
   (lambda (i)
     (define-key cacoo-my-minor-mode-keymap
       (if (stringp (car i))
           (read-kbd-macro (car i)) (car i))
       (cdr i)))
   cacoo-my-map-alist)
  (define-key cacoo-minor-mode-keymap (kbd "M-c") 'cacoo-my-minor-mode-keymap)
  )

;;; color-thema.el
;;; (auto-install-from-emacswiki "color-theme.el")
;;; 用意されているカラーテーマを使える
(my-safe-require 'color-theme)

;;; 自作カラーテーマ
;;; (auto-install-from-emacswiki "pink-bliss.el")
(my-safe-require 'pink-bliss)

;;; viewer.el
;;; 2011-02-05 (Sat)
;;; (auto-install-from-emacswiki "viewer.el")
;;; view-mode を便利に
(my-safe-require 'viewer
  (setq view-read-only t)
  ;; 書き込み不能なファイルはview-modeで開くように
  (viewer-stay-in-setup)
  ;; 特定のファイルは view-mode で開く
  (setq view-mode-by-default-regexp "\\.log$")
  ;; view-mode ではカーソル色を青にする
  ;; Emacs24 の view-mode でカーソルが青くなるのは
  ;; ibus.el の設定で、ibus が使えないときにカーソルが
  ;; 青くなるからだった。
  ;; (when (<= emacs-major-version 23)
  ;;   (defadvice view-mode (before set-view-mode-cursor-color activate)
  ;;     "Before execute view-mode, set cursor-color blue."
  ;;     (if view-mode
  ;;         (set-cursor-color "yellow")
  ;;       (set-cursor-color "blue"))))
  ;; 結局ややこしいのでつけないことにした

  ;; view-mode の時モードラインを色づけ
  (setq viewer-modeline-color-unwritable "tomato")
  (setq viewer-modeline-color-view "orange")
  (viewer-change-modeline-color-setup)
  ;; 閲覧用キーマップ
  (defvar pager-keybind
    `( ;; vi-like
      ("h" . backward-char)
      ("l" . forward-char)
      ("k" . previous-line)
      ("j" . next-line)
      ("K" . ,(lambda () (interactive) (previous-line 4)))
      ("J" . ,(lambda () (interactive) (next-line 4)))
      ("0" . move-beginning-of-line)
      ("^" . back-to-indentation)
      ("$" . move-end-of-line)
      ;; ("b" . inertias-up)               ; inertial-scroll に変更。微妙か。
      ;; ("f" . inertias-down)
      ("b" . scroll-down)
      ("f" . scroll-up)
      ("\C-u" . ,(lambda () (interactive) (scroll-down (/ (window-height) 2))))
      ("\C-d" . ,(lambda () (interactive) (scroll-up (/ (window-height) 2))))
      ("p" . ,(lambda (arg) (interactive "p") (scroll-down arg)))
      ("n" . ,(lambda (arg) (interactive "p") (scroll-up arg)))
      ;("y" . ,(lambda () (interactive) (scroll-down 1)))
      ("e" . jaunte)
      ("g" . ,(lambda (line) (interactive "p") (goto-line line)))
      ("G" . end-of-buffer)
      ("M" . move-to-window-line-top-bottom)
      ("H" . ,(lambda () (interactive) (move-to-window-line 0)))
      ("L" . ,(lambda () (interactive) (move-to-window-line -1)))
      ("z" . recenter-top-bottom)
      ;; bm-easy
      ("m" . bm-toggle)
      ("[" . bm-previous)
      ("]" . bm-next)
      ;; langhelp-like
      ("c" . scroll-other-window-down)
      ("v" . scroll-other-window)
      ))
  (defun define-many-keys (keymap key-table &optional includes)
    (let (key cmd)
      (dolist (key-cmd key-table)
        (setq key (car key-cmd)
              cmd (cdr key-cmd))
        (if (or (not includes) (member key includes))
            (define-key keymap key cmd))))
    keymap)

  (defun view-mode-hook0 ()
    (define-many-keys view-mode-map pager-keybind)
    ;;(hl-line-mode 1)
    (define-key view-mode-map " " 'scroll-up))
  (add-hook 'view-mode-hook 'view-mode-hook0)
  )

;;; bm.el
;;; 2011-02-05 (Sat)
;;; (auto-install-from-url "http://cvs.savannah.gnu.org/viewvc/*checkout*/bm/bm/bm.el")
;;; 可視ブックマークをつける。たぶん本来のブックマークとは違うけど。
(setq-default bm-buffer-persistence t)
(setq bm-restore-repository-on-load t)
(my-safe-require 'bm
  (add-hook 'after-init-hook 'bm-repository-load)
  (add-hook 'find-file-hooks 'bm-buffer-restore)
  (add-hook 'after-revert-hook 'bm-buffer-restore)
  (add-hook 'kill-buffer-hook 'bm-buffer-save)
  (add-hook 'after-save-hook 'bm-buffer-save)
  (add-hook 'kill-emacs-hook '(lambda ()
                                (bm-buffer-save-all)
                                (bm-repository-save)))
  (global-set-key (kbd "M-M") 'bm-toggle)
  (global-set-key (kbd "M-[") 'bm-previous)
  (global-set-key (kbd "M-]") 'bm-next))

;;; one-key.el
;;; 2011-02-05 (Sat)
;;; (auto-install-from-emacswiki "one-key.el")
;;; (auto-install-from-emacswiki "one-key-config.el")
;;; (auto-install-from-emacswiki "one-key-default.el")
;; (my-safe-require 'one-key
;;   (my-safe-require 'one-key-default)                       ; one-key.el も一緒に読み込んでくれる
;;   (my-safe-require 'one-key-config)                        ; one-key.el の基本設定をしてくれる
;;   (one-key-default-setup-keys)                     ; one-key- で始まるメニュー使える様になる
;;   (setq one-key-help-window-max-height 40)         ; ウィンドウの最大高さ
;;                                         ; nil だとものすごい大きい *One-Key* バッファが一面に広がってしまうことがあるので。
;;   (setq one-key-items-per-line nil)
;;   (define-key global-map (kbd "C-S-r") 'one-key-menu-C-x-r) ; C-S-r を C-x r と同じにする
;;   (define-key global-map (kbd "C-4") 'one-key-menu-C-x-4) ; C-4 を C-x 4 と同じにする
;;   (define-key global-map (kbd "C-5") 'one-key-menu-C-x-5) ; C-5 を C-x 5 と同じにする
;;   (define-key global-map (kbd "<C-return>") 'one-key-menu-C-x-RET) ; C-RET を C-x RET と同じにする

;;   ;; (my-safe-load "one-key-menu-my-mode-specific")                   ; 自作 mode-specific キーバインド
;;   ;; (add-to-list 'one-key-mode-alist '(mode-specific . one-key-menu-my-mode-specific))
;;   ;; (add-to-list 'one-key-toplevel-alist '(("type key here" . "my-mode-specific") . one-key-menu-my-mode-specific))
;;   ;; (define-key global-map (kbd "C-c") 'one-key-menu-my-mode-specific)

;;   (eval-after-load "yatex"
;;     '(progn
;;        (my-safe-load "one-key-menu-my-YaTeX-begin")      ; 自作 yatex キーバインド表
;;        (add-to-list 'one-key-mode-alist '(yatex-mode . one-key-menu-my-YaTeX-begin))
;;        (add-to-list 'one-key-toplevel-alist '(("type key here" . "my-YaTeX-begin") . one-key-menu-my-YaTeX-begin))
;;        (add-hook 'yatex-mode-hook
;;                  '(lambda () (YaTeX-define-key (kbd "b") 'one-key-menu-my-YaTeX-begin)))))
;;   (eval-after-load "wl"
;;     '(progn
;;        (my-safe-load "one-key-menu-my-wl-folder") ; template wl-folder-mode 用キーバインド表
;;        (add-to-list 'one-key-mode-alist '(wl-folder-mode . one-key-menu-my-wl-folder))
;;        (add-to-list 'one-key-toplevel-alist '(("type key here" . "my-wl-folder") . one-key-menu-my-wl-folder))
;;        (add-hook 'wl-folder-mode-hook
;;                  '(lambda () (define-key wl-folder-mode-map (kbd "?") 'one-key-menu-my-wl-folder)))
;;        (my-safe-load "one-key-menu-my-wl-summary") ; template wl-summary-mode 用キーバインド表
;;        (add-to-list 'one-key-mode-alist '(wl-summary-mode . one-key-menu-my-wl-summary))
;;        (add-to-list 'one-key-toplevel-alist '(("type key here" . "my-wl-summary") . one-key-menu-my-wl-summary))
;;        (add-hook 'wl-summary-mode-hook
;;                  '(lambda () (define-key wl-summary-mode-map (kbd "?") 'one-key-menu-my-wl-summary)))))
;;   (eval-after-load "elscreen"
;;     '(progn
;;        (my-safe-load "one-key-menu-my-elscreen") ; template elscreen 用キーバインド表
;;        (add-to-list 'one-key-mode-alist '(elscreen . one-key-menu-my-elscreen))
;;        (add-to-list 'one-key-toplevel-alist '(("type key here" . "my-elscreen") . one-key-menu-my-elscreen))
;;        (define-key global-map (kbd "C-z") 'one-key-menu-my-elscreen)))
;;   )

;;; key-chord.el
;;; 2011-02-05 (Sat)
;;; (auto-install-from-emacswiki "key-chord.el")
;;; キーボード同時押しでコマンドを実行する
(my-safe-require 'key-chord
  (setq key-chord-two-keys-delay 0.05)
  (setq key-chord-one-keys-delay 0.05)
  (key-chord-mode 1)
  (key-chord-define global-map "nb" 'switch-to-buffer)
  (key-chord-define global-map "jk" 'view-mode)
  (key-chord-define global-map "df" 'describe-function)
  (key-chord-define global-map "dv" 'describe-variable)
  (key-chord-define global-map "dk" 'describe-key)
  (key-chord-define global-map "db" 'describe-bindings)
  (key-chord-define global-map "dm" 'describe-mode)
  (key-chord-define global-map "AA" 'anything-apropos)
  (key-chord-define global-map "cc" 'org-capture)
  ;; (key-chord-define global-map "CC" 'org-capture)
  (key-chord-define global-map "hl" 'global-hl-line-mode)
  (key-chord-define global-map "gs" 'magit-status)
  (key-chord-define global-map "kb" '(lambda () (interactive) (kill-buffer)))
  (key-chord-define global-map "sn" 'elscreen-next)
  (key-chord-define global-map "sp" 'elscreen-previous)
  (key-chord-define global-map "@0" 'delete-window)
  (key-chord-define global-map "@1" 'delete-other-windows)
  (key-chord-define global-map "@2" 'split-window-vertically)
  (key-chord-define global-map "@3" 'split-window-horizontally)
  (key-chord-define global-map "bm" 'bm-toggle)
  (key-chord-define global-map "b[" 'bm-previous)
  (key-chord-define global-map "b]" 'bm-next)
  ;; (eval-after-load "org"
  ;;   (eval-after-load "anything-orgcard"
  ;;     '(key-chord-define org-mode-map "dm" 'aoc:anything-orgcard)))
  )

;;; slime
;;; 2011-02-05 (Sat)
;;; cvs -d :pserver:anonymous:anonymous@common-lisp.net:/project/slime/cvsroot co slime
;;; Common Lisp 用マイナーモード
;;; HyperSpec という Common Lisp 用のリファレンスがあるらしいのでいつか入れよう
(setq inferior-lisp-program "clisp")
(my-safe-require 'slime
  (slime-setup)
  ;; 日本語利用
  (setq slime-net-coding-system 'utf-8-unix)
  ;; カーソル付近にある単語の情報を表示
  ;;(slime-autodoc-mode)
  )

;;; xdvi-search.el
;;; 2011-02-04 (Fri)
;;; (auto-install-from-url "http://xdvi.sourceforge.net/xdvi-search.el")
;;; Emacs から xdvi に飛ぶ
(my-safe-require 'xdvi-search
  (add-hook 'yatex-mode-hook
            '(lambda ()
               (YaTeX-define-key (kbd "C-d") 'xdvi-jump-to-line)))
  ;; xdvi-jump-to-line しても xdvi にフォーカスが移らないので、移るようにする
  ;; 簡易すぎるので複数 xdvi が立ち上がっているとダメかも？
  ;; はじめて defadvice を使ったが便利ちゃんだ
  (defadvice xdvi-jump-to-line (after xdvi-search-focus-to-xdvi activate)
    "After xdvi-jum-to-line, focus to xdvik"
    (shell-command "wmctrl -a xdvi")))
;; --src-special の指定はお忘れなく
;; TeX-master というローカル変数を相対パスで指定する（もしくは ~ を含めると
;; いけないのかもしれない）とうまく動かないので注意

;;; minibuf-isearch.el
;;; 2011-01-27 (Thu)
;;; (auto-install-from-url "http://www.sodan.org/~knagano/emacs/minibuf-isearch/minibuf-isearch.el")
;;; minibufferで履歴検索
(my-safe-require 'minibuf-isearch)

;;; popwin.el
;;; 2011-01-21 (Fri)
;;; https://github.com/m2ym/popwin-el/tree/v0.2
;;; (auto-install-from-url "https://raw.github.com/m2ym/popwin-el/master/popwin.el")
;;; ポップアップウィンドウインターフェースを提供
(my-safe-require 'popwin
  (setq display-buffer-function 'popwin:display-buffer)
  ;(setq special-display-function 'popwin:special-display-popup-window)   ; display-buffer-function を変更したくない場合こっち
  (push '("*Buffer List*" :position right :width 0.5) popwin:special-display-config)
  (push '("*nav-help*" :height 0.5) popwin:special-display-config)
  (push '("*Shell Command Output*" :height 0.5 :noselect t) popwin:special-display-config)
  (push '("*Apropos*" :height 0.5) popwin:special-display-config)
  (push '(" *auto-async-byte-compile*" :height 0.4 :position bottom :noselect t) popwin:special-display-config)
  (push '("*One-Key*" :position bottom :noselect t) popwin:special-display-config) ; ウィンドウが多いと表示されるのが遅い気がする。
                                        ; しかも表示されるウィンドウの高さが一定でない気もする。どうしてだろう。
  (push '("*sdic*" :height 0.25 :position top :noselect t) popwin:special-display-config)
  ;(push '("*anything complete" :width 0.4 :position right) popwin:special-display-config)
  (add-to-list 'popwin:special-display-config '("*quickrun*"))
  (push '("*YaTeX-typesetting*" :height 15 :position bottom :noselect t) popwin:special-display-config) ; なぜか効かない
  (push '("*MATLAB Help*" :position right :width 0.4) popwin:special-display-config)
  (define-key ctl-x-map (kbd "p") 'popwin:display-last-buffer)
  )

;;; latex-math-preview.el
;;; (auto-install-from-emacswiki "latex-math-preview.el")
;;; tex 中の数式をプレビューする http://www16.atwiki.jp/ytk5/pages/13.html
(my-safe-require 'latex-math-preview
  (autoload 'latex-math-preview-expression "latex-math-preview" nil t)
  (autoload 'latex-math-preview-insert-symbol "latex-math-preview" nil t)
  (autoload 'latex-math-preview-save-image-file "latex-math-preview" nil t)
  (autoload 'latex-math-preview-beamer-frame "latex-math-preview" nil t)
  (add-hook 'yatex-mode-hook
            '(lambda ()
               (YaTeX-define-key "p" 'latex-math-preview-expression)
               (YaTeX-define-key "\C-p" 'latex-math-preview-save-image-file)
               (YaTeX-define-key "j" 'latex-math-preview-insert-symbol)
               (YaTeX-define-key "\C-j" 'latex-math-preview-last-symbol-again)
               ;(YaTeX-define-key "\C-b" 'latex-math-preview-beamer-frame)
               ))
  (setq latex-math-preview-in-math-mode-p-func 'YaTeX-in-math-mode-p) ; 数式の判断に yatex のものを使う
  ;; 用いるパッケージ
  (setq latex-math-preview-latex-template-header
        "\\documentclass{article}
\\pagestyle{empty}
\\usepackage{amsmath,amssymb,amsthm}
\\usepackage{bm}")
  ;; プレビューする書式を追加
  (add-to-list 'latex-math-preview-match-expression 
               '(0 . "\\\\begin{table\\(\\|\\*\\)}\\(\\(.\\|\n\\)*?\\)\\\\end{table\\(\\|\\*\\)}")) ; table 環境
  ;; latex ではなく platex を使用するように変更．また， dvipng だと日本語非対応なので gs-to-png にする。のは無理だった。
  (setq latex-math-preview-tex-to-png-for-preview '(platex dvipng))
  (setq latex-math-preview-tex-to-png-for-save '(platex dvipng))
  ;(setq latex-math-preview-tex-to-png-for-preview '(platex dvips-to-eps gs-to-png))
  ;(setq latex-math-preview-tex-to-png-for-save '(platex dvipdfmx gs-to-png))
  (setq latex-math-preview-tex-to-eps-for-save '(platex dvips-to-eps))
  (setq latex-math-preview-tex-to-ps-for-save '(platex dvips-to-ps))
  (setq latex-math-preview-beamer-to-png '(platex dvipdfmx gs-to-png))

  (add-to-list 'latex-math-preview-command-option-alist '(gs-to-png "-q" "-dSAFER" "-dNOPAUSE" "-dBATCH" "-sDEVICE=png16m" "-dEPSCrop" "-r600")))

;;; twittering-mode.el
;;; 2011-01-17 (Mon)
;;; (auto-install-from-url "https://github.com/hayamiz/twittering-mode/raw/master/twittering-mode.el")
;;; Emacs でツイッター
(my-safe-require 'twittering-mode
  ;(setq twittering-use-master-password t)
  (setq twittering-auth-method 'xauth)
  (setq twittering-username "kbkbkbkb1")
  (setq twittering-icon-mode t)
  (setq twittering-fill-column 50)
  (setq twittering-status-format "%i %s / %S,  %@:\n%FOLD{%T}\n  from %f%L%r%R\n ") ; 表示のフォーマット

  (setq twittering-initial-timeline-spec-string ;   最初からから開くタイムライン
        '(":home"
          ":search/emacs/"
          ":search/keysnail/"))
  ;; バッファ名に [twitter] を追加する
  ;(defadvice twittering-start (after my-twittering-start-add-buffer-name activate)
  ;  (rename-buffer (concat (buffer-name) " [twitter]")))
  ; :home にしか追加されなかった．どの関数にアドバイスすればいいかわからん・・・
  )

;;; calfw.el
;;; 2011-01-07 (Fri)
;;; http://d.hatena.ne.jp/kiwanami/20110107/1294404952 より
;;; (auto-install-from-url "https://github.com/kiwanami/emacs-calfw/raw/master/calfw.el")
;;; 高機能カレンダー
;; 日本の祝日関連
;; (auto-install-from-url "http://www.meadowy.org/meadow/netinstall/export/799/branches/3.00/pkginfo/japanese-holidays/japanese-holidays.el")
(add-hook 'calendar-load-hook
          (lambda ()
            (my-safe-require 'japanese-holidays)
            (setq calendar-holidays
                  (append japanese-holidays local-holidays other-holidays))))
(setq mark-holidays-in-calendar t)
;; 祝日の設定を先にしてないといけないっぽい
(my-safe-require 'calfw
  ;; iCalender形式と連携
  ;; (auto-install-from-url "https://github.com/kiwanami/emacs-calfw/raw/master/calfw-ical.el")
  (my-safe-require 'calfw-ical)

  ;; 2011-06-20 (Mon)
  ;; org-mode と連携
  ;; (auto-install-from-url "https://raw.github.com/kiwanami/emacs-calfw/master/calfw-org.el")
  (my-safe-require 'calfw-org)

  ;; calfw-gcal.el
  ;; かるふわから google カレンダーを編集できる
  ;; (auto-install-from-url "https://github.com/myuhe/calfw-gcal.el/raw/master/calfw-gcal.el")
  (my-safe-require 'calfw-gcal
    (define-key cfw:calendar-mode-map (kbd "a") 'cfw:gcal-main)
    )

  ;; カレンダーを開く関数
  (defun my-open-calendar ()
    (interactive)
    (cfw:open-calendar-buffer
     :view 'month
     :contents-sources
     (list
      (cfw:org-create-source "Seagreen4") ; color
      (cfw:ical-create-source "g03090416" "https://www.google.com/calendar/ical/g03090416%40gmail.com/private-96087f02e8d133b8d7bab6e5a0712574/basic.ics" "#2952a3")
      (cfw:ical-create-source "Bachelor" "https://www.google.com/calendar/ical/b6ufn2dbm0s5sgjdjbg3gt58ec%40group.calendar.google.com/public/basic.ics" "Brown")
      (cfw:ical-create-source "Master" "https://www.google.com/calendar/ical/m.rotation%40gmail.com/public/basic.ics" "Blue")
      (cfw:ical-create-source "Doctor" "https://www.google.com/calendar/ical/a2qvdfsjl78ismt8rbqf7eujdk%40group.calendar.google.com/public/basic.ics" "Red")
      (cfw:ical-create-source "Kenkyuu" "https://www.google.com/calendar/ical/9ga8oggl0tnk5j0todp0kqs0qd1d1l0b%40import.calendar.google.com/public/basic.ics" "Orange")
      )))
  )

;;; org-mode.el
;;; org-mode 自体は標準であるが非標準elispも必要そうなので
;;; ここに書いておく
(my-safe-require 'org-install
  (define-key org-mode-map (kbd "C-,") nil) ; available cycle-buffer
  (setq org-startup-truncated nil)
  (setq org-return-follows-link t)
  (add-to-list 'auto-mode-alist '("\\.org$" . org-mode))
  (setq org-directory (expand-file-name "memo"  dropbox-directory))
  (setq org-default-notes-file (expand-file-name "memo.org" org-directory))
  (setq org-export-html-coding-system 'utf-8)
  ;; for MobileOrg
  (setq org-mobile-directory (expand-file-name "MobileOrg" dropbox-directory))
  (setq org-mobile-inbox-for-pull
        (expand-file-name "mobile-capture.org" org-directory)) ; MobileOrg のキャプチャをかきこむファイル
  ;; org-mobile-files の評価値が (org-agenda-files) なので MobileOrg で同期される
  (setq org-agenda-files `(,org-default-notes-file
                           ,(expand-file-name "task.org" org-directory)
                           ,(expand-file-name "contract.org" org-directory)
                           ,(expand-file-name "english.org" org-directory)
                           ,org-mobile-inbox-for-pull))

  (setq org-tag-alist '(("Bookmark" . ?b)
                        ("Emacs" . ?) ("Research" . ?r) ("Lab" . ?l) ("Misc" . ?m)
                        ("Idea" . ?i) ("Survey" . ?v) ("Server" . ?s) ("Note" . ?n)
                        ("Home" . ?h) ("Firefox" . ?) ("Question" . ?q) ("Vi" . ?)
                        ("Item" . ?t) ("Experiment" . ?e) ("Computer" . ?C) ("Shop" . ?o)
                        ("Apple" . ?A) ("Later" . ?L)
                        ("Program" . ?p) ("Tool" . ?T) ("Adobe" . ?) ("Event" . ?E)
                        ("Ubuntu" . ?) ("Debian" . ?) ("Windows" . ?) ("Blog" . ?)
                        ("OrgMode" . ?) ("Lecture" . ?c) ("Linux" . ?) ("Git" . ?G)
                        ("JobHunt" . ?j) ("MATLAB" . ?M) ("TeX" . ?) ("PukiWiki" . ?)
                        ("Shell" . ?) ("はてな" . ?)))
  (setq org-todo-keywords '((sequence "TODO" "|" "DROP" "DONE")))
  (setq org-log-done 'time) ; DONEの時刻を記録
  (setq org-capture-templates
        `(("m" "Today's memo" entry
           (file+function nil my-search-org-headline)
           "* %?\n" :empty-lines 1)
          ("o" "Other day's memo" entry
           (file+function nil (lambda () (my-search-org-headline t)))
           "** %?\n" :empty-lines 1)
          ("b" "Bookmark" entry
           (file+function nil my-search-org-headline)
           "** %?\n%(concat \"   [[\" (jk/moz-url) \"]]\")\n   Entered on %U\n"
           :empty-lines 1)
          ("h" "はてな" entry
           (file+headline "hatena.org" "Draft")
           "** %?" :empty-lines 1)
          ("a" "Article" entry
           (file+headline "article.org" "Draft")
           "** %?\n" :empty-lines 1)
          ("t" "Test" entry
           (file+headline ,(concat org-directory "/test.org") ,(format-time-string "%Y-%m-%d (%a)"))
           "* %?\n   %T" :empty-lines 1 :prepend t)
          ("i" "Idea" entry
           (file+headline nil "New Ideas")
           "** %?\n   %a\n   %t")))
  ;; publish の設定
  (setq org-publish-project-alist
        `(("orgfiles"
           :base-directory ,org-directory
           :publishing-directory ,(concat org-directory "/html")
           :base-extension "org"
           :publishing-function org-publish-org-to-html
           :headline-levels 3
           :section-numbers nil
           :table-of-contents t
           :style "<link rel=stylesheet type=\"text/css\" href=\"stylesheet.css\" >"
           :exclude-tags ("noexport" "Note")
           :auto-preamble t
           :auto-postamble nil)
          ("images"
          :base-directory ,(concat org-directory "/html")
          :base-extension "jpg\\|jpeg\\|png"
          :publishing-directory ,(concat org-directory "/html/img")
          :publishing-function org-publish-attachment)
         ("others"
          :base-directory ,org-directory
          :base-extension "css"
          :publishing-directory ,(concat org-directory "/html")
          :publishing-function org-publish-attachment)
         ("website" :components ("orgfiles" "images" "others"))))
  ;; config about latex exporting
  (setq org-export-latex-coding-system 'utf-8-unix)
  (setq org-latex-to-pdf-process '("latexmk -pdfdvi %f")) ; process for tex->pdf
  (setq org-export-latex-date-format "%Y-%m-%d")
  (setq org-export-latex-default-class "jsarticle")
  (setq org-export-latex-classes nil)
  (add-to-list 'org-export-latex-classes
               '("jsarticle"
                 "\\documentclass[a4j]{jsarticle}"
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
                 ("\\paragraph{%s}" . "\\paragraph*{%s}")
                 ("\\subparagraph{%s}" . "\\subparagraph*{%s}")
                 ))
  (setcar (member '("" "graphicx" t) org-export-latex-default-packages-alist)
          '("dvipdfmx" "graphicx" t))   ; add option to graphicx package
  ; default package
  (setcar (member '("" "hyperref" nil) org-export-latex-default-packages-alist)
          '("dvipdfmx,%\n%colorlinks=true,%\nbookmarks=true,%\nbookmarksnumbered=false,%\nbookmarkstype=toc,%\npdftitle={},%\npdfsubject={},%\npdfauthor={},%\npdfkeywords={},%\n"
            "hyperref" nil))
  (add-to-list 'org-export-latex-default-packages-alist
               '("dvipdfmx" "color" nil)
               t)
  (add-to-list 'org-export-latex-default-packages-alist
               "\\AtBeginDvi{\\special{pdf:tounicode EUC-UCS2}} % prevent mojibake of bookmark in pdf"
               t)
  ;; config about beamer export
  (add-to-list 'org-export-latex-classes
               '("beamer"
                 "\\documentclass[compress,dvipdfmx]{beamer}"
                 org-beamer-sectioning
                 ))
  ;; Because completion string of template alist is lower case, upcase it.
  (setq org-structure-template-alist
        (mapcar '(lambda (elm)
                   (cons (car elm)
                         (cons (upcase (nth 1 elm))
                               (cddr elm))))
                org-structure-template-alist))
  ;; hook
  (add-hook 'org-mode-hook 'auto-fill-mode)
  ;; key bind
  (define-key global-map (kbd "C-c a") 'org-agenda)
  (define-key global-map (kbd "C-c b") 'org-iswitchb)
  (define-key global-map (kbd "C-c l") 'org-store-link)
  (define-key global-map (kbd "C-c C-SPC") 'org-mark-ring-goto)

  ;; from info
  (defun org-summary-todo (n-done n-not-done)
    "すべてのサブツリーが終了するとDONEに切り替えます。その他の場合は、TODOに
なります。"
    (let (org-log-done org-log-states)   ; 記録「logging」を終了
      (org-todo (if (= n-not-done 0) "DONE" "TODO"))))
  (add-hook 'org-after-todo-statistics-hook 'org-summary-todo)

  ;; external plugin
;;; org-tree-slide.el
;;; (auto-install-from-url "https://raw.github.com/takaxp/org-tree-slide/master/org-tree-slide.el")
  (my-safe-require 'org-tree-slide
    (org-tree-slide-simple-profile)
    (setq org-tree-slide-heading-emphasis t)
    )

  ;; anything source for src block
  (defvar org-src-my-lang-candidates
    '("asymptote" "awk" "calc" "C" "C++" "clojure" "css" "ditaa" "dot" "emacs-lisp"
      "gnuplot" "haskell" "java" "js" "latex" "ledger" "lisp" "lilypond" "matlab"
      "mscgen" "ocaml" "octave" "org" "oz" "perl" "plantuml" "python" "R" "ruby"
      "sass" "scheme" "screen" "sh" "sql" "sqlite")
    "Anything command source for Org-mode src block")
  (defvar anything-c-source-org-src-lang
    '((name . "Available language in Org-mode src block")
      (candidates . org-src-my-lang-candidates)
      (action ("Return as string" . eval)
              ("Return as symbol" . intern)
              ("Insert string" . insert))))


  )

(defun my-search-org-level1 ()
  "Search org-mode level1 headline."
  (interactive)
  (re-search-forward "^\\* \\(.*\\)$" nil t))

;; だいたいの場合でうまくいくようになった．
;; あとは新規に日にちの headline を作ったときにうまく * の数が合わないのを調整したい
(defun my-search-org-headline (&optional other-day)
  ""
  (interactive)
  (let* ((standard-time '(948115 18560)) ; bce 1/12/31 から 1970/01/01 までの経過秒
         (date (format-time-string
                "%Y-%m-%d (%a)"
                (if other-day
                    (org-read-date nil t nil "Date for tree entry:" (current-time))
                  (current-time))))
         )
    (beginning-of-buffer)
    (if (re-search-forward (concat "^\\* " date) nil t)
        ;; headline corresponding to date is found
        (progn
          ;; (my-search-org-level1)
          ;(forward-char)
          ;; (goto-line (- (current-line) 2)) ; カーソルが行頭にあるときと，そうでない時で current-line の挙動が異なるのが
          ;;                                  ; 気になりますが，my-search-org-level1 をしたときは
          ;;                                  ; 行頭にないはずなので，大丈夫かな
          ;(beginning-of-line)
          (forward-line 1)
          )
      ;; search where new headline is insearted
      ;; 日付(level1)が降順になっていることが前提
      (re-search-forward "^\\* \\(.*\\)" nil t)
      (while (string<  date (match-string-no-properties 1))
        (re-search-forward "^\\* \\(.*\\)" nil t))
      (beginning-of-line)
      (insert (concat "* " date "\n"))
      ;(backward-char)

      )))

;;; rubikitch さんの例
;;; http://d.hatena.ne.jp/rubikitch/20100819/org
;; (require 'org-capture)
;; (defun org-capture-demo ()
;;   (interactive)
;;   (let ((file "/tmp/org-capture.org")
;; 	org-capture-templates)
;;     (find-file-other-window file)
;;     (unless (save-excursion
;;               (goto-char 1)
;;               (search-forward "* test\n" nil t))
;;       (insert "* test\n** entry\n"))
;;     (other-window 1)
;;     (setq org-capture-templates
;; 	  `(("a" "ふつうのエントリー後に追加" entry
;; 	     (file+headline ,file "entry")
;; 	     "* %?\n%U\n%a\n")
;; 	    ("b" "ふつうのエントリー前に追加" entry
;; 	     (file+headline ,file "entry")
;; 	     "* %?\n%U\n%a\n" :prepend t)
;; 	    ("c" "即座に書き込み" entry
;; 	     (file+headline ,file "entry")
;; 	     "* immediate-finish\n" :immediate-finish t)
;; 	    ("d" "ナローイングしない" entry
;; 	     (file+headline ,file "entry")
;; 	     "* 全体を見る\n\n" :unnarrowed t)
;; 	    ("e" "クロック中のエントリに追加" entry (clock)
;; 	     "* clocking" :unnarrowed t)
;; 	    ("f" "リスト" item
;; 	     (file+headline ,file "list")
;; 	     "- リスト")
;; 	    ;; うまく動かない
;; 	    ("g" "チェックリスト" checkitem
;; 	     (file+headline ,file "list")
;; 	     "チェックリスト")
;; 	    ("h" "表の行" table-line
;; 	     (file+headline ,file "table")
;; 	     "|表|")
;; 	    ("i" "そのまま" plain
;; 	     (file+headline ,file "plain")
;; 	     "あいうえお")
;; 	    ("j" "ノードをフルパス指定して挿入" entry
;; 	     (file+olp ,file "test" "entry")
;; 	     "* %?\n%U\n%a\n")
;; 	    ;; これもうまく動かない
;; 	    ("k" "ノードを正規表現指定して挿入" entry
;; 	     (file+regexp ,file "list")
;; 	     "* %?\n%U\n%a\n")
;; 	    ;; 年月日エントリは追記される
;; 	    ("l" "年/月/日のエントリを作成する1" entry
;; 	     (file+datetree ,file))
;; 	    ("m" "年/月/日のエントリを作成する2" item
;; 	     (file+datetree ,file))
;; 	    ("o" "年/月/日のエントリを作成する prepend" entry
;; 	     (file+datetree ,file) "* a" :prepend t)))
;;     (org-capture)))
;; (global-set-key "\C-x\C-z" 'org-capture-demo)

;; (org-remember-insinuate)
;; (setq org-remember-templates
;;       '(("Todo" ?t "** TODO %?\n   %i\n   %a\n" nil)
;;         ("Bug" ?b "** TODO %?   :bug:\n   %i\n   %a\n   %t" nil "Inbox")
;;         ("Idea" ?i "** %?\n   %i\n   %a\n   %t" nil "New Ideas")
;;         ))
;; org-capture が新しいそうなのでそっちに変更

;; はてなへのエクスポート
(my-safe-require 'org-export-hatena)

;;; google-maps.el
;;; 2011-01-04 (Tue)
;;; Google Map を表示する
;; (auto-install-from-url "http://git.naquadah.org/?p=google-maps.git;a=blob_plain;f=google-maps-base.el;hb=HEAD")
;; (auto-install-from-url "http://git.naquadah.org/?p=google-maps.git;a=blob_plain;f=google-maps-geocode.el;hb=HEAD")
;; (auto-install-from-url "http://git.naquadah.org/?p=google-maps.git;a=blob_plain;f=google-maps-static.el;hb=HEAD")
;; (auto-install-from-url "http://git.naquadah.org/?p=google-maps.git;a=blob_plain;f=google-maps.el;hb=HEAD")
;; (auto-install-from-url "http://git.naquadah.org/?p=google-maps.git;a=blob_plain;f=org-location-google-maps.el;hb=HEAD")
(my-safe-require 'google-maps)

;;; jaunte.el
;;; 2010-12-31 (Fri)
;;; (auto-install-from-url "https://raw.github.com/kawaguchi/jaunte.el/master/jaunte.el")
;;; http://kawaguchi.posterous.com/emacshit-a-hint
;;; Hit a Hint でカーソル移動
(my-safe-require 'jaunte
  (define-key mode-specific-map "e" 'jaunte)) ; C-c e で Hit a Hint 移動

;;; postit.el
;;; 2010-12-16 (Thu)
;;; http://web.archive.org/web/19981202211943/www.is.s.u-tokyo.ac.jp/~tama/source.html より
;;; (auto-install-from-url "http://chasen.org/~daiti-m/dist/postit.el")
;;; ファイルにポストイット
;(my-safe-require 'postit)
;; 今のところあまりつかっていない

;;; text-adjust.el
;;; 2010-12-16 (Thu)
;;; http://d.hatena.ne.jp/rubikitch/20090220/text_adjust より
;;; (auto-install-from-url "http://taiyaki.org/elisp/mell/src/mell.el")
;;; (auto-install-from-url "http://taiyaki.org/elisp/text-adjust/src/text-adjust.el")
;;; テキストの細かいところを修正し，統一する
(my-safe-require 'text-adjust)
;; ファイル保存時に自動的に text-adjust を起動する
;; (defun text-adjust-before-save-if-needed ()
;;   (when (memq major-mode
;;               '(org-mode text-mode change-log-mode yatex-mode))
;;     (text-adjust-buffer)))
;; (defalias 'spacer 'text-adjust-space-buffer)
;; (add-hook 'before-save-hook 'text-adjust-before-save-if-needed)
;; ソースファイルの時なんかに勝手に整形するのは危険なのでコメントアウト

;;; windows.el (revive.el もあったほうがいい)
;;; 2010-12-13 (Mon)
;;; Meadow/Emacs memo より
;;; (auto-install-from-url "http://www.gentei.org/~yuuji/software/windows.el")
;;; (auto-install-from-url "http://www.gentei.org/~yuuji/software/revive.el")
;;; ウィンドウの分割情報を保存する
;; prefix 変更。require の前にしないといけないっぽい
;; (setq win:switch-prefix "\C-z")
;; (setq win:use-frame nil)   ; 新規にフレームを作らない
;; (my-safe-require 'windows
;;   ;(win:startup-with-window)               ; 起動時に window1 を選択する？
;;   (define-key ctl-x-map (kbd "C-c") 'see-you-again)
;;   (define-key ctl-x-map (kbd "C") 'save-buffers-kill-emacs)
;;   (define-key global-map (kbd "C-S-n") 'win-next-window)
;;   (define-key global-map (kbd "C-S-p") 'win-prev-window)
;;   ;; revive.el によりレジューム
;;   ;(add-hook 'after-init-hook 'resume-windows)      ; 起動時にレジュームする
;;   ;; これをつけるとエラーが起きる。なんか bm のところで止まってる？
;;   ;; 少々めんどいが毎回手作業でレジュームすることにする
;;   ;; (aset win:names-prefix 2 "tex") ; なんとなくこれでウィンドウタイトルを変えられそう
;;   )

;;; elscreen.el
;;; 2010-12-13 (Mon)
;;; ftp://ftp.morishima.net/pub/morishima.net/naoto/ElScreen/ よりダウンロード
;;; ウィンドウの分割情報を保持しておく
(my-safe-load "elscreen"
  (setq elscreen-display-tab 10)
  (setq elscreen-tab-display-kill-screen nil) ; タブのXを非表示
  (define-key global-map (kbd "C-S-n") 'elscreen-next)
  (define-key global-map (kbd "C-S-p") 'elscreen-previous)
  (define-key global-map (kbd "M-n") 'elscreen-next)
  (define-key global-map (kbd "M-p") 'elscreen-previous)
  (define-key global-map (kbd "M-1") '(lambda () (interactive) (elscreen-goto 1)))
  (define-key global-map (kbd "M-2") '(lambda () (interactive) (elscreen-goto 2)))
  (define-key global-map (kbd "M-3") '(lambda () (interactive) (elscreen-goto 3)))
  (define-key global-map (kbd "M-4") '(lambda () (interactive) (elscreen-goto 4)))
  (define-key global-map (kbd "M-5") '(lambda () (interactive) (elscreen-goto 5)))
  (define-key global-map (kbd "M-6") '(lambda () (interactive) (elscreen-goto 6)))
  (define-key global-map (kbd "M-7") '(lambda () (interactive) (elscreen-goto 7)))
  (define-key global-map (kbd "M-8") '(lambda () (interactive) (elscreen-goto 8)))
  (define-key global-map (kbd "M-9") '(lambda () (interactive) (elscreen-goto 9)))
  (define-key global-map (kbd "M-0") '(lambda () (interactive) (elscreen-goto 10)))  ; なんか愚直すぎるので何とかしたいですね

  ;; 起動時にスクリーンを9個作っておく
  (defun my-elscreen-startup ()
    (let ((i 1))
      (while (< i 10)
        (elscreen-create)
        (setq i (1+ i)))))
  (add-hook 'after-init-hook 'my-elscreen-startup)

  ;; elscreen のタブの並びと数字キーの並びを合わせる
  ;; 既存スクリーンのリストを要求された際、0 番が存在しているかのように偽装する
  (defadvice elscreen-get-screen-list (after my-ad-elscreen-get-screenlist disable)
    (add-to-list 'ad-return-value 0))
  ;; スクリーン生成時に 0 番が作られないようにする
  (defadvice elscreen-create (around my-ad-elscreen-create activate)
    (interactive)
    ;; 0 番が存在しているかのように偽装
    (ad-enable-advice 'elscreen-get-screen-list 'after 'my-ad-elscreen-get-screenlist)
    (ad-activate 'elscreen-get-screen-list)
    ;; 新規スクリーン生成
    ad-do-it
    ;; 偽装解除
    (ad-disable-advice 'elscreen-get-screen-list 'after 'my-ad-elscreen-get-screenlist)
    (ad-activate 'elscreen-get-screen-list))
  ;; スクリーン 1 番を作成し 0 番を削除 (起動時、フレーム生成時用)
  (defun my-elscreen-kill-0 ()
    (when (and (elscreen-one-screen-p)
               (elscreen-screen-live-p 0))
      (elscreen-create)
      (elscreen-kill 0)))
  ;; フレーム生成時のスクリーン番号が 1 番になるように
  (defadvice elscreen-make-frame-confs (after my-ad-elscreen-make-frame-confs activate)
    (let ((selected-frame (selected-frame)))
      (select-frame frame)
      (my-elscreen-kill-0)
      (select-frame selected-frame)))
  ;; 起動直後のスクリーン番号が 1 番になるように
  (add-hook 'after-init-hook 'my-elscreen-kill-0)

  )

;;; php-mode.el
;;; 2010-12-13 (Mon)
;;; http://sourceforge.net/projects/php-mode/ よりダウンロード
;;; phpファイルを扱う
(my-safe-require 'php-mode
  (add-hook 'php-mode-user-hook
            '(lambda ()
               (setq tab-width 2)
               (setq indent-tabs-mode nil))))

;;; sudo-ext.el
;;; 2010-12-12 (Sun)
;;; http://d.hatena.ne.jp/rubikitch/20101018/sudoext より
;;; (auto-install-from-emacswiki "sudo-ext.el")
;;; Emacs 内から sudo をつかう
(my-safe-require 'sudo-ext)

;;; mozc.el
;;; Google 日本語入力オープンソース版
;;; Emacs でMozcを使う
;;; 要 mozc-emacs-helper
;; (my-safe-require 'mozc)
;; (setq default-input-method "japanese-mozc")

;;; ibus.el
;;; http://www11.atwiki.jp/s-irie/pages/21.html より
;;; Emacsでibusを使えるようにする．これでmozcが使える
(when (linuxp)
  (my-safe-require 'ibus
    ;; Turn on ibus-mode automatically after loading .emacs
    (add-hook 'after-init-hook 'ibus-mode-on)
    ;; Use C-SPC for Set Mark command
    (ibus-define-common-key ?\C-\s nil)
    ;; Use C-/ for Undo command
    (ibus-define-common-key ?\C-/ nil)
    ;; Change cursor color depending on IBus status
    (setq ibus-cursor-color '("limegreen" "yellow" "light gray"))
    ;; Use C-\ for ibus-toggle
    (define-key global-map (kbd "C-\\") 'ibus-toggle)
    ;; `ibus-common-function-key-list' に ibus で使いたいキーを追加する？
    (add-to-list 'ibus-common-function-key-list '(meta "v"))
    ))

;;; session.el
;;; 2010-11-22 (Sun)
;;; Meadow/Emacs memo より
;;; http://sourceforge.net/projects/emacs-session/files/ からダウンロード
;;; Emacsが終了した時のミニバッファ履歴やカーソル位置を保存する
(my-safe-require 'session
  (add-hook 'after-init-hook 'session-initialize)
  (setq session-globals-include '((kill-ring 50)
                                  (session-file-alist 500 t)
                                  (file-name-history 3000))
        session-globals-max-string 100000000
        history-length t)     ; ミニバッファ履歴リストの長さ制限を無くす
  ;; 最後に保存した位置ではなく，閉じた時の位置を復元する
  (setq session-undo-check -1)
  ;; If you want to use both desktop and session, use:
  (setq desktop-globals-to-save '(desktop-missing-file-warning))
  ;; 定期的に session を保存
  (run-at-time t 60 'session-save-session)
  )

;;; auto-install.el
;;; 2010-11-06 (Sat)
;;; Emacsテクニックバイブル より
;;; (auto-install-from-emacswiki "auto-install.el")
;;; elispインストーラ
;; auto-installによってインストールされるEmacs Lispをロードパスに加える
;; デフォルトは ~/.emacs.d/auto-install/
(my-safe-require 'auto-install
  ;; 起動時にEmacsWikiのページ名を補完候補に加える
  (auto-install-update-emacswiki-package-name t)
  ;; install-elisp.el互換モードのにする
  (auto-install-compatibility-setup)
  ;; ediff関連のバッファを１つのフレームにまとめる
  (setq ediff-window-setup-function 'ediff-setup-windows-plain))

;;; auto-async-byte-compile.el
;;; 2010-11-06 (Sat)
;;; Emacsテクニックバイブル より
;;; 非同期自動バイトコンパイル
;; (auto-install-from-emacswiki "auto-async-byte-compile.el")
(my-safe-require 'auto-async-byte-compile
  ;; 自動バイトコンパイルを無効にするファイル名の正規表現
  (setq auto-async-byte-compile-exclude-files-regexp "diary\\|/junk/")
  (add-hook 'emacs-lisp-mode-hook 'enable-auto-async-byte-compile-mode)
  )

;;; recentf-ext.el
;;; 2010-11-06 (Sat)
;;; Emacsテクニックバイブル より
;;; (auto-install-from-emacswiki recentf-ext.el)
;;; 最近開いたファイルを開く
(my-safe-require 'recentf-ext
  ;; 最近のファイル3000個を保存する
  (setq recentf-max-saved-items 3000)
  ;; 最近使ったファイルに加えないファイルを正規表現で指定する
  (setq recentf-exclude '("/TAGS$" "/var/tmp/" "Temp_ExternalEditor"))
  ;(define-key mode-specific-map "r" 'recentf-open-files) ; C-c r で最近使ったファイルを開く
  ; anything-fo-files で代替できるので変更
  ;; automatically save recentf file and supress messages
  ;; http://masutaka.net/chalow/2011-10-30-2.html
  (defvar my-recentf-list-prev nil)

  (defadvice recentf-save-list
    (around no-message activate)
    "If `recentf-list' and previous recentf-list are equal,
do nothing. And suppress the output from `message' and
`write-file' to minibuffer."
    (unless (equal recentf-list my-recentf-list-prev)
      (flet ((message (format-string &rest args)
                      (eval `(format ,format-string ,@args)))
             (write-file (file &optional confirm)
                         (let ((str (buffer-string)))
                           (with-temp-file file
                             (insert str)))))
        ad-do-it
        (setq my-recentf-list-prev recentf-list))))

  (defadvice recentf-cleanup
    (around no-message activate)
    "suppress the output from `message' to minibuffer"
    (flet ((message (format-string &rest args)
                    (eval `(format ,format-string ,@args))))
      ad-do-it))

  (setq recentf-auto-cleanup 60)
  (run-with-idle-timer 60 t 'recentf-save-list)
  )

;;; pukiwiki-mode
;;; 2010-09-11 (Sat)
;;; Meadow/Emacs memo より
(my-safe-require 'http)
(my-safe-require 'pukiwiki-mode
  (setq pukiwiki-auto-insert t)
  (autoload 'pukiwiki-edit "pukiwiki-mode" "pukwiki-mode." t)
  (autoload 'pukiwiki-index "pukiwiki-mode" "pukwiki-mode." t)
  (autoload 'pukiwiki-edit-url "pukiwiki-mode" "pukwiki-mode." t)
  (setq pukiwiki-site-list
        '(("bibouroku" "http://rubner.mydns.jp/pukiwiki/index.php" nil utf-8-unix)
          ("gavo" "http://www.gavo.t.u-tokyo.ac.jp/members-only/pukiwiki/index.php" nil utf-8-unix)
          ("minerva" "http://minerva.gavo.t.u-tokyo.ac.jp/wiki/index.php" nil utf-8-unix)
          ("eeic09" "http://eeic09.dip.jp/index.php" nil utf-8-unix)
          ("disgaea4" "http://alphawiki.net/disgaea4/index.php" nil euc-jp)))
  ;; Proxy server
  ;(setq http-proxy-server "localhost")
  ;(setq http-proxy-port 1080)
  ;; ローカルにファイルを保存する
  (setq pukiwiki-directory (concat user-emacs-directory "pukiwiki-save"))
  (setq pukiwiki-save-post-data t)
  ;; pukiwiki-edit-mode で行を折り返さない
  (add-hook 'pukiwiki-edit-mode '(lambda ()
                                   (toggle-truncate-lines 1)
                                   (orgtbl-mode 1)))
  )

;;; clmemo.el
;;; 2010-08-20 (Fri)
;;; http://pop-club.hp.infoseek.co.jp/emacs/clmemo.html より
;;; ChangeLogでメモを取るモード
(autoload 'clmemo "clmemo" "ChangeLog memo mode." t)
(setq clmemo-file-name (concat dropbox-directory "/memo/clmemo.txt")) ; a file to edit
(setq clmemo-title-list '(("survey" . "論文調査") "Emacs" ("kenkyuu" . "研究")
                          ("idea" . "アイデア"))) ; タイトルのリスト
(setq clmemo-time-string-with-weekday t) ; add weekday to date
(define-key ctl-x-map (kbd "M") 'clmemo)

;; google search
(my-safe-load "google")

;;; shell-command.el
;;; シェルの強化
;;; (auto-install-from-url "http://namazu.org/~tsuchiya/elisp/shell-command.el")
(my-safe-require 'shell-command
  (shell-command-completion-mode))

;; display-deadline.el
;(my-safe-require 'display-deadline)
;(display-deadline "進捗報告まであと%d日%h時間%m分" (encode-time 0 0 10 15 11 2010))

;;; line-number
;(my-safe-require 'wb-line-number)
;(set-scroll-bar-mode nil)
;(setq wb-line-number-scroll-bar t)
;(wb-line-number-toggle)
;;; wb-line-numberは微妙だったのでlinum-modeで
;(global-linum-mode 1)

;;; yatex.el
;; yatex-mode の起動

(setq auto-mode-alist
      (cons (cons "\\.tex\\'" 'yatex-mode) auto-mode-alist))
(autoload 'yatex-mode "yatex" "Yet Another LaTeX mode" t)
(eval-after-load "yatex"
  (progn
    (setq tex-command "latexmk -pdfdvi -pv"       ; latexmk は複数回のコンパイル支援
          makeindex-command "mendex"
          bibtex-command "pbibtex"
          dviprint-command-format "dvipdfmx %s"
          dvi2-command "pxdvi -geo +0+0 -s 4" ; xdvi='pxdvi' のエイリアスをはってるのだが，
                                        ; このコマンドはエイリアスを見てくれないようなので直接指定する
          YaTeX-kanji-code 4  ;; 文章作成時の日本語文字コード
          ;; 0: no-converion
          ;; 1: Shift JIS (windows & dos default)
          ;; 2: ISO-2022-JP (other default)
          ;; 3: EUC
          ;; 4: UTF-8
          )
    (setq YaTeX-inhibit-prefix-letter 1)    ; prefix を C-c C-英字 にする．1 にすると C-c 大文字英字 が無効になる
    (setq YaTeX-use-AMS-LaTeX t)            ; ams パッケージの補完を可能にする

    ;; (setq YaTeX-sectioning-indent 2)
    ;; (setq YaTeX-environment-indent 2)
    (add-hook 'yatex-mode-hook          ; every time hook when yatex-mode is executed
              '(lambda ()
                 (auto-fill-mode 1)         ; auto-fill-mode enabled
                 (reftex-mode 1)            ; reftex-mode enabled
                 (flyspell-mode 1)          ; flyspell-mode enabled
                 (outline-minor-mode 1)
                 ;; setting for outline-minor-mode
                 (setq outline-level 'latex-outline-level)
                 (setq outline-regexp-alist
                       '(("documentclass" . -2)
                         ("part" . -1)
                         ("chapter" . 0)
                         ("section" . 1)
                         ("subsection" . 2)
                         ("subsubsection" . 3)
                         ("paragraph" . 4)
                         ("subparagraph" . 5)
                         ("appendix" . 0)))
                 (setq outline-regexp
                       (concat "[ \t]*\\\\\\("
                               (mapconcat 'car outline-regexp-alist "\\|")
                               "\\)\\*?[ \t]*[[{]"))
                 ))
    (add-hook 'yatex-mode-load-hook     ; one time hook when yatex.el is loaded
              '(lambda ()
                 (define-key YaTeX-mode-map (kbd "<backtab>") 'outline-my-global-cycle)
                 (define-key YaTeX-mode-map (kbd "C-c C-p") 'outline-previous-visible-heading)
                 (define-key YaTeX-mode-map (kbd "C-c C-n") 'outline-next-visible-heading)
                 (YaTeX-my-set-sectioning-face)
                 ))
    ))

(defun YaTeX-my-set-sectioning-face ()
    (set-face-background 'YaTeX-sectioning-1 "#1c27ee")
    (set-face-background 'YaTeX-sectioning-3 "#7874cc")
    (set-face-background 'YaTeX-sectioning-4 "#d66abb"))

;; function to find hierarchy for LaTeX
(defun latex-outline-level ()
  (save-excursion
    (looking-at outline-regexp)
    (let* ((title (buffer-substring-no-properties (match-beginning 1) (match-end 1))))
      (if (assoc title outline-regexp-alist)
          (assoc-default title outline-regexp-alist)
        (length title)))))

;; cycle outline level
(defun outline-my-cycle-level ()
  (interactive)
  (when (outline-on-heading-p)
    (beginning-of-line)
    (let* ((visible-eol (save-excursion (move-end-of-line nil) (point)))
           (eos (save-excursion (outline-end-of-subtree) (point)))
           (cur-level (funcall outline-level))
           (next-level (save-excursion (outline-next-heading)
                                       (when (outline-on-heading-p)
                                         (funcall outline-level))))
           (has-children (and next-level (< cur-level next-level))))
      (if (and (eq visible-eol eos))
          (progn
            (show-children)
            (show-entry)
            (message (if has-children "CHILDREN" "SUBTREE (NO CHILDREN)")))
        (if (and has-children
                 (save-excursion (outline-next-heading)
                                 (= (next-overlay-change (point)) (point-at-eol))))
            (progn (show-subtree)
                   (message "SUBTREE"))
          (hide-subtree)
          (message "FOLDED")
          )))
    ;(hide-leaves)
    ;(outline-end-of-heading)
    ;(outline-end-of-subtree)
    ))
(defadvice YaTeX-indent-line (around cycle-heading activate)
  "If cursor is on outline heading, cycle heading. Otherwise indent line."
  (if (outline-on-heading-p)
      (outline-my-cycle-level)
    ad-do-it))

(defun outline-my-global-cycle ()
  (interactive)
  (if (eq last-command 'outline-my-global-cycle)
        (hide-sublevels 1000)
    (hide-sublevels 1))
  )
;; Use Emacs23's eldoc
(my-safe-require 'eldoc
  ;; (auto-install-from-emacswiki "eldoc-extension.el")
  ;;(my-safe-require 'eldoc-extension)  ; これをつけるとWarningが起こるのでとりあえず
  (setq eldoc-idle-delay 0.05)
  (setq eldoc-echo-area-use-multiline-p t)
  (add-hook 'emacs-lisp-mode-hook 'turn-on-eldoc-mode)
  (add-hook 'lisp-interaction-mode-hook 'turn-on-eldoc-mode)
  (add-hook 'ielm-mode-hook 'turn-on-eldoc-mode))
;; use c-eldoc
(my-safe-load "c-eldoc"
  (add-hook 'c-mode-hook
            (lambda ()
              (set (make-local-variable 'eldoc-idle-delay) 0.20)
              (c-turn-on-eldoc-mode)
              )))

;;;;;;;;;;;;;; 動的略語展開 ;;;;;;;;;;;;;;;;
;;; 日本語でも快適に動的略語展開
(my-safe-load "dabbrev-ja")

;;; auto-complete.el
;;; ポップアップメニューで自動補完
(my-safe-require 'auto-complete-config
  ;; メジャーモードに関する辞書
  (add-to-list 'ac-dictionary-directories
               (expand-file-name "ac-dict" user-emacs-directory))
  ;; (if (and (linuxp) (= emacs-major-version 23))
  ;;     nil
  ;;   (ac-config-default))
  ;; 23 でも大丈夫になったらしい 2011-06-04 (Sat)
  (ac-config-default)
  (setq ac-auto-show-menu 0.08)       ; 補完メニュー表示の遅延時間
  (setq ac-quick-help-delay 0.5)     ; help 表示の遅延時間
  (define-key my-original-map (kbd "TAB") 'auto-complete) ; あえて手動で補完したい時
  (setq ac-use-overriding-local-map t) ; ローカルマップの TAB を乗っ取る？
                                        ; おもに org-mode で使いたいので付けとく．
                                        ; 本来の org-mode の TAB がどれほど使えなくなるのかが心配

  ;; デフォルトの情報源
  (setq-default ac-sources
                '(ac-source-filename ac-source-features
                  ac-source-functions ac-source-yasnippet
                  ac-source-variables ac-source-symbols
                  ac-source-abbrev ac-source-dictionary ac-source-words-in-same-mode-buffers))
  ;; auto-complete を有効にするモード
  (setq ac-modes (append
                  '(yatex-mode matlab-mode matlab-shell-mode ruby-mode org-mode)
                  ac-modes))
  (add-hook 'sh-mode-hook
            (lambda ()
                   (add-to-list 'ac-sources 'ac-source-yasnippet)))
  ;; key bind
  (define-key ac-complete-mode-map (kbd "<C-tab>") 'yas/expand)
  )

(my-measure-message-time "Non-standard elisp setting.")
;;;;;;;;;;;;;;;;; 外部プログラムが必要そうなやつ ;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;; ポータブルにはしにくそうなやつ ;;;;;;;;;;;;;;;;
;;; lookup
;;; 2011-05-15 (Sun)
;;; 多機能辞書引きプログラム
;; オートロードの設定
;; (autoload 'lookup "lookup" nil t)
;; (autoload 'lookup-region "lookup" nil t)
;; (autoload 'lookup-word "lookup" nil t)
;; (autoload 'lookup-select-dictionaries "lookup" nil t)
;; dictionary setting
(setq lookup-search-agents
             '((ndeb "~/dict/EIJIRO126-epwing")
               (ndeb "~/dict/LDOCE5")
               (ndeb "~/dict/KOJIEN6")
               (ndeb "~/dict/Wikip0723Lite/epwing")
               ;(ndeb "~/.emacs.d/dict/EDICT")
               ;(ndeb "~/.emacs.d/dict/WORDNET")
               ;(ndeb "~/.emacs.d/dict/WEB")
               ;(ndeb "~/.emacs.d/dict/YASOU")
               ))
(setq lookup-default-dictionary-options
      '((:stemmer .  stem-english)))
(my-safe-require 'lookup
  ;; remove an inflected suffix
  ;(lookup-set-dictionary-options "ndeb:~/.emacs.d/dict/WORDNET/wordnet" ':stemmer 'stem-english) ; うまくいかん？

  ;; key bind
  (define-key mode-specific-map (kbd "d") 'lookup-pattern)
  (define-key mode-specific-map (kbd "D") 'lookup-select-dictionaries)
  )

;; ispell (スペルチェック)
;; コマンドの設定
(my-safe-require 'ispell
  (setq ispell-program-name "ispell")
  (setq ispell-grep-command "grep") ; デフォルトの egrep が Cygwin ではシンボリックリンク
                                        ; なので，Meadow から起動できない
  (setq ispell-personal-dictionary "~/.ispell_default") ; 個人用辞書
  ;; 日本語ファイル中の英単語スペルチェックを可能にする
  (eval-after-load "ispell"
    '(add-to-list 'ispell-skip-region-alist '("[^\000-\377]")))
                                        ; tex の記法は無視
  (add-hook 'yatex-mode-hook (function (lambda () (setq ispell-parser 'tex)))))

;;; migemo.el
;;; 2010-11-12 (Fri)
;;; Emacsテクニックバイブル より
;;; C/Migemo は自分でコンパイル
;;; ローマ字で日本語検索
(when (executable-find "cmigemo")
  (my-safe-require 'migemo
    (setq migemo-command "cmigemo")
    (setq migemo-options '("-q" "--emacs")); "-i" "\a"))
    ;; migemo-dict のパスを指定
    ;; 辞書の文字コードを指定．
    (cond ((winp)
           ;; utf-8 でも動かんことはないが，cp932 のほうがよく動く
           ;; そもそも，なぜかすべてのローマ字を正規表現に変換できない．大文字にしたりしなかったりで
           ;; 変換結果が異なる．おそらく文字コードの問題だとは思われるが詳細不明．
           ;; キャッシュが残っていて、過去の検索パターン展開が適用されてたのが原因だった
           ;(setq migemo-pattern-alist-file (concat user-emacs-directory ".migemo-pattern-sjis"))
           (setq migemo-dictionary
                 (expand-file-name "dict/utf-8/migemo-dict"
                                   (file-name-directory (executable-find "cmigemo"))))
           (setq migemo-coding-system 'utf-8-unix))
          ((linuxp)
           ;(setq migemo-pattern-alist-file (concat user-emacs-directory ".migemo-pattern-utf"))
           (setq migemo-dictionary "/usr/local/share/migemo/utf-8/migemo-dict")
           (setq migemo-coding-system 'utf-8-unix)))
    (setq migemo-pattern-alist-file (concat user-emacs-directory ".migemo-pattern"))
    (setq migemo-user-dictionary nil)
    (setq migemo-regex-dictionary nil)
    ;; キャッシュ機能を利用する
    (setq migemo-use-pattern-alist t)
    (setq migemo-use-frequent-pattern-alist t)
    (setq migemo-pattern-alist-length 1024)
    ;; 起動時に初期化も行う
    (migemo-init)))

;;; use emacs-w3m
(autoload 'w3m "w3m"
  "Interface for w3m on Emacs." t)
(autoload 'w3m-find-file "w3m"
  "Find a local file using emacs-w3m." t)
(autoload 'w3m-search "w3m-search"
  "Search words using emacs-w3m." t)
(autoload 'w3m-weather "w3m-weather"
  "Display a weather report." t)
(autoload 'w3m-antenna "w3m-antenna"
  "Report changes of web sites." t)
(autoload 'w3m-namazu "w3m-namazu"
  "Search files with Namazu." t)
;; need to visit login website
(eval-after-load "w3m"
  '(progn
     (setq w3m-use-cookies t)
     (define-key w3m-mode-map (kbd "F") 'w3m-view-next-page)
     (define-key w3m-mode-map (kbd "f") 'w3m-scroll-up-or-next-url)
     (define-key w3m-mode-map (kbd "e") 'my-w3m-HaH) ; w3m-edit-this-url
     (define-key w3m-mode-map (kbd "C-l") 'w3m-goto-url) ; recenter-top-bottom
     (define-key w3m-mode-map (kbd "z") 'recenter-top-bottom)
     ))
(eval-after-load "w3m-search"
  '(progn
     (setq w3m-search-engine-alist (append
                                    '(("kakaku" "http://kakaku.com/search_results/?query=%s")
                                      ("eow" "http://eow.alc.co.jp/%s/UTF-8/")
                                      ("Wikipedia" "http://ja.wikipedia.org/wiki/%s")
                                      ("google scholar" "http://scholar.google.co.jp/scholar?q=%s&hl=ja&lr=")
                                      ("amazon" "http://www.amazon.co.jp/s/ref=nb_sb_noss?__mk_ja_JP=%u30AB%u30BF%u30AB%u30CA&url=search-alias%3Daps&field-keywords=%s")) ; うまく動かん
                                    w3m-search-engine-alist))
     (setq w3m-uri-replace-alist (append
                                   '(("\\`k:" w3m-search-uri-replace "kakaku")
                                     ("\\`d:" w3m-search-uri-replace "eow")
                                     ("\\`g:" w3m-search-uri-replace "google")
                                     ("\\`w:" w3m-search-uri-replace "Wikipedia")
                                     ("\\`gs:" w3m-search-uri-replace "google scholar")
                                     ("\\`a:" w3m-search-uri-replace "amazon"))
                                   w3m-uri-replace-alist))
     ))

(defun my-w3m-HaH ()
  "Visit url by hit-a-hint.
文字の部分も jaunte の候補が出てしまうので
改良の余地有り。またボタンが押せないのはどうしようね。"
  (interactive)
  (jaunte)
  (w3m-view-this-url))


;;; wanderlust
;;; 2010-11-08 (Mon)
;;; メーラー
;;; 設定は .wl, .folders で
;; SSL/TLS 用証明書ストアのパス
;(setq ssl-certificate-directory (concat dropbox-directory "/certs"))
(setq ssl-certificate-verification-policy 1)

(autoload 'wl "wl" "Wanderlust" t)
(autoload 'wl-other-frame "wl" "Wanderlust on new frame." t)
(autoload 'wl-draft "wl-draft" "Write draft with Wanderlust." t)
(setq wl-init-file (concat user-emacs-directory ".wl"))
(setq wl-folders-file (concat user-emacs-directory ".folders"))

;;; use matlab-mode
;;; http://d.hatena.ne.jp/uhiaha888/20100815/1281888552
(autoload 'matlab-mode "matlab" "Enter MATLAB mode." t)
(autoload 'matlab-shell "matlab" "Interactive MATLAB mode." t)
(setq auto-mode-alist (delete '("\\.m\\'" . objc-mode) auto-mode-alist)) ; .m ファイルが object-c に解釈されないようにする
(add-to-list 'auto-mode-alist '("\\.m\\'" . matlab-mode))
(setq matlab-shell-command "/usr/local/bin/matlab"
      matlab-shell-command-swithes '("-nodesktop -v=glnx86")
      matlab-indent-level 2
      matlab-indent-function-body nil
      matlab-highlight-cross-function-variables t
      matlab-return-add-semicolon t
      matlab-show-mlint-warnings t
      mlint-programs '("/usr/local/matlab75/bin/glnx86/mlint")
      matlab-mode-install-path (list (expand-file-name "/usr/local/matlab75/")))
(autoload 'mlint-minor-mode "mlint" nil t)
(add-hook 'matlab-mode-hook (lambda ()
                              (mlint-minor-mode 1)
                              ;; config about face for mlint
                              (set-face-background 'linemark-go-face "gray40")
                              (set-face-background 'linemark-funny-face "red")
                              ))
;; mlint しようとすると， linemark.el が必要らしいが，require したらしたで
;; おかしいので使わないようにしよう．
;; cedet から linemark.el だけコピーしてロードしたら何とか動くようだ．
(add-hook 'matlab-mode-hook (lambda () (auto-fill-mode 0)))
(add-hook 'matlab-shell-mode-hook 'ansi-color-for-comint-mode-on)
(add-hook 'matlab-shell-mode-hook
           (lambda () (setenv "LANG" "C")))
(eval-after-load "shell"
  '(define-key shell-mode-map [down] 'comint-next-matching-input-from-input))
(eval-after-load "shell"
  '(define-key shell-mode-map [up] 'comint-previous-matching-input-from-input))
(eval-after-load "matlab"
  '(progn
     (define-key matlab-mode-map (kbd "M-;") 'nil))) ; matlab-mode で dwim-comment をつかう
     ;; (define-key matlab-shell-mode-map (kbd "<tab>") 'ac-complete)
     ;; (define-key matlab-shell-mode-map (kbd "C-<tab>") 'matlab-shell-tab)))

(defface ac-matlab-candidate-face
  '((t (:background "PaleGreen" :foreground "black")))
  "Face for matlab candidate."
  :group 'auto-complete)

(defface ac-matlab-selection-face
  '((t (:background "DarkGreen" :foreground "white")))
  "Face for matlab selected candidate."
  :group 'auto-complete)

(defun matlab-complete-symbol-list (&optional arg)
  (interactive "P")
  ;(matlab-navigation-syntax
    (let* ((prefix (if (and (not (eq last-command 'matlab-complete-symbol))
			    (member (preceding-char) '(?  ?\t ?\n ?, ?\( ?\[ ?\')))
		       ""
		     (buffer-substring-no-properties
		      (save-excursion (forward-word -1) (point))
		      (point))))
	   (sem (matlab-lattr-semantics prefix)))
      (if (not (eq last-command 'matlab-complete-symbol))
	  (setq matlab-last-prefix prefix
		matlab-last-semantic sem
		matlab-completion-search-state
		(cond ((eq sem 'solo)
		       '(matlab-solo-completions
			 matlab-find-user-functions
			 matlab-find-recent-variable))
		      ((eq sem 'boolean)
		       '(matlab-find-recent-variable
			 matlab-boolean-completions
			 matlab-find-user-functions
			 matlab-value-completions))
		      ((eq sem 'value)
		       '(matlab-find-recent-variable
			 matlab-find-user-functions
			 matlab-value-completions
			 matlab-boolean-completions))
		      ((eq sem 'property)
		       '(matlab-property-completions
			 matlab-find-user-functions
			 matlab-find-recent-variable
			 matlab-value-completions))
		      (t '(matlab-find-recent-variable
			   matlab-find-user-functions
			   matlab-value-completions
			   matlab-boolean-completions)))))

      (let ((allsyms (apply 'append
			    (mapcar (lambda (f) (funcall f prefix))
				    matlab-completion-search-state))))
	(matlab-uniquafy-list allsyms))))

(defvar ac-source-matlab
  '((candidates
     . (lambda ()
	 (matlab-complete-symbol-list)))
    (candidate-face . ac-matlab-candidate-face)
    (selection-face . ac-matlab-selection-face)
    ))

(defvar ac-source-matlab-functions nil
  "Souce for matlab functions.")
(setq ac-source-matlab-functions
      '((candidates . (list "zeros" "ones" "eye" "mean" "exp" "length" "save" "normpdf" "plot"
                            "size" "print" "sum" "prod" "inv" "diag" "rand" "randn" "linspace"
                            "logspace" "length" "any" "all" "find" "reshape" "meshgrid" "char"
                            "deblank" "double" "strcmp" "strncmp" "isletter" "isspace" "findstr"
                            "strrep" "int2str" "num2str" "str2num" "dec2hex" "dec2bin" "hex2dec"
                            "bin2dec" "mat2str" "eval" "tic" "toc" "figure" "hold" "subplot"
                            "fplot" "title" "xlabel" "ylabel" "text" "gtext" "grid" "axis"
                            "legend" "set" "get" "bar" "barh" "area" "pie" "hist" "stem"
                            "staris" "compass" "feather" "quiver" "contour" "ginput" "drawnow"
                            "image" "imagesc" "image" "imread" "fill" "fprintf" "fopen"
                            "fclose" "fgetl" "feof" "fwrite" "fread"))
        (document . ac-matlab-function-documentation)
        (symbol . "f")))

(defun ac-matlab-function-documentation (fnc)
  "Show document of matlab function."
  (condition-case nil
      (matlab-shell-collect-command-output (concat "help " fnc))
    (error "You need to run the command `matlab-shell' to read help!")))


(add-hook 'matlab-mode-hook
	  (lambda ()
	    (add-to-list 'ac-sources 'ac-source-matlab)
	    (add-to-list 'ac-sources 'ac-source-matlab-functions)
            (key-chord-define matlab-mode-map "df" 'matlab-shell-describe-command)
            (key-chord-define matlab-mode-map "dv" 'matlab-shell-describe-variable)
            (key-chord-define matlab-mode-map "AA" 'matlab-shell-apropos)
            ))

(add-hook 'matlab-shell-mode-hook
	  (lambda ()
	    (add-to-list 'ac-sources 'ac-source-matlab)
	    (add-to-list 'ac-sources 'ac-source-matlab-functions)
            (key-chord-define matlab-shell-mode-map "df" 'matlab-shell-describe-command)
            (key-chord-define matlab-shell-mode-map "dv" 'matlab-shell-describe-variable)
            (key-chord-define matlab-shell-mode-map "AA" 'matlab-shell-apropos)
            ))




;;; プロンプトじゃない場所から comint-previous-input を
;;; 実行したとき，プロンプトに移動する
;;; 2011-06-30 (Thu)
(defadvice comint-previous-input
  (before comint-previous-input-anywhere activate)
  (if (not (comint-after-pmark-p))
      (end-of-buffer)))

;;; ややこしい機能を有効にする設定
(put 'scroll-left 'disabled nil)
(put 'downcase-region 'disabled nil)
(put 'upcase-region 'disabled nil)
(put 'dired-find-alternate-file 'disabled nil)
(put 'narrow-to-region 'disabled nil)

(my-measure-message-time "Big elisp setting.")
