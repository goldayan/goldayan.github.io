;; Set the package installation directory so that packages aren't stored in the
;; ~/.emacs.d/elpa path.
(require 'package)
(setq package-user-dir (expand-file-name "./.packages"))
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("elpa" . "https://elpa.gnu.org/packages/")))

;; Initialize the package system
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

;; Install use-package
(unless (package-installed-p 'use-package)
  (package-install 'use-package))
(require 'use-package)

;; Install dependencies
(use-package htmlize
  :ensure t)

(use-package webfeeder
  :ensure t)

;; Set language environment
(set-language-environment "UTF-8")

;; Load the publishing system
(require 'ox-publish)

(defun goldayan/head-extra ()
  (concat
   "<link href=\"https://fonts.cdnfonts.com/css/share-tech-mono\" rel=\"stylesheet\">"
   "<link rel=\"stylesheet\" type=\"text/css\" href=\"/assets/code.css\"/>"
   "<link rel=\"stylesheet\" type=\"text/css\" href=\"/assets/style.css\"/>"))

;; Website template
(defun org-html-template (contents info)
  "Custom HTML template for org-publish"
  (concat "<!DOCTYPE html>"
"<html>"
  "<head>"
    (concat "<!-- " (org-export-data (org-export-get-date info "%Y-%m-%d") info) " -->")
    (org-html--build-meta-info info)
    (org-html--build-head info)
  "</head>"
  "<body>"
    "<header>"
      "<div class=\"container\">"
	"<h1>Gold Ayan's Tinker Garage</h1>"
      "</div>"
      "<div class=\"header-content\">"
	"<nav class=\"container\">"
	  "<ul class=\"topnav\">"
	    "<li><a href=\"/index.html\">Home</a></li>"
	    "<li><a href=\"/projects.html\">Projects</a></li>"
	    "<li><a href=\"/posts\">Posts</a></li>"
	    "<li><a href=\"/til.html\">TIL</a></li>"
	    "<li><a href=\"/blogrolls.html\">Blogrolls</a></li>"
	    "<li><a href=\"/feed.xml\">RSS</a></li>"
	  "</ul>"
	"</nav>"
      "</div>"
    "</header>"

    "<article class=\"container\">"
      "<div class=\"blog-content\">"
      contents
      "</div>"
    "</article>"

    "<footer>"
      "This site is made with ❤️ using Emacs."
    "</footer>"

  "</body>"
"</html>"
))

;; Customize the HTML output
(setq org-html-validation-link nil            ;; Don't show validation link
      org-html-head-include-scripts nil       ;; Use our own scripts
      org-html-head-include-default-style nil ;; Use our own styles
      org-html-htmlize-output-type 'css
      ;;org-publish-use-timestamps-flag t
      ;;org-publish-timestamp-directory "./.org-cache/"
      )

;; Define the publishing project
(setq org-publish-project-alist
      (list
       (list "goldayan:main"
             :recursive t
             :base-directory "./content"
	     :base-extension "org"
	     :html-head-extra (goldayan/head-extra)
             :publishing-function 'org-html-publish-to-html
             :publishing-directory "./public"
	     :htmlized-source t
             :with-author nil           ;; Don't include author name
             :with-creator nil          ;; Include Emacs and Org versions in footer
             :with-toc nil              ;; Include a table of contents
             :section-numbers nil       ;; Don't include section numbers
             :time-stamp-file nil)      ;; Don't include time stamp in file
       (list "goldayan:assets"          ;; Copy all the assets - images, css and js
             :recursive t
             :base-directory "./assets"
	     :base-extension "css\\|js\\|png\\|jpg\\|gif\\|pdf\\|mp3\\|html\\|mp4\\|ico"
             :publishing-function 'org-publish-attachment
             :publishing-directory "./public/assets")))    

;; Generate the site output
(org-publish-all t)

(message "Build complete!")

;; RSS builder

(webfeeder-build "./feed.xml"
                   "./public"
                   "https://goldayan.in"
                   (delete "posts/index.html" (let ((default-directory (expand-file-name "./public")))
                     (directory-files-recursively "posts" ".*\\.html$")))
                   :builder 'webfeeder-make-rss
                   :title "Gold Ayan's Tinker Garage"
                   :description "Let’s tinker!"
                   :author "Gold Ayan")

