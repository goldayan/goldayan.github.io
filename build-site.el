;; -*- lexical-binding: t; -*-
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

(add-to-list 'load-path (expand-file-name "./dependency/org-publish-rss/"))
(require 'org-publish-rss)

;; Debugging org publish rss
(message "Is org-publish-rss loaded? %s" (featurep 'org-publish-rss))

;; Set language environment
(set-language-environment "UTF-8")

;; Load the publishing system
(require 'ox-publish)

(defvar goldayan/head-extra
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

;; Helper functions for Org keywords, drafts, and tags
(defun goldayan/get-org-keyword (file keyword)
  "Extract the value of a #+KEYWORD: from an org FILE (case-insensitive)."
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-min))
    (let ((case-fold-search t))
      (when (re-search-forward (format "^#\\+%s:[ \t]*\\(.*\\)$" (regexp-quote keyword)) nil t)
        (string-trim (match-string 1))))))

(defun goldayan/org-file-draft-p (file)
  "Return t if FILE is marked as a draft (#+draft: true/t/yes/1)."
  (let ((val (goldayan/get-org-keyword file "draft")))
    (and val (member (downcase val) '("true" "t" "yes" "1")))))

(defun goldayan/org-file-has-tag-p (file target-tag)
  "Return t if FILE has TARGET-TAG in its #+tags: or #+filetags: keyword."
  (let ((val (or (goldayan/get-org-keyword file "tags")
                 (goldayan/get-org-keyword file "filetags"))))
    (when val
      ;; Support both comma-separated ("emacs, guix") and colon-separated (":emacs:guix:")
      (let ((tags (mapcar #'string-trim (split-string val "[,:]+" t))))
        (member (downcase target-tag) (mapcar #'downcase tags))))))

;; Filter function for main RSS feed
(defun goldayan/rss-filter-main (file)
  "Filter function for main RSS feed: include non-draft articles in posts/."
  (and (string-match-p "/posts/" file)
       (not (string-equal (file-name-nondirectory file) "index.org"))
       (not (goldayan/org-file-draft-p file))))

;; Custom tag-specific RSS feeds
(defvar goldayan/rss-custom-tags
  '("emacs" "linux")
  "List of tags to generate individual RSS feeds for (e.g. emacs.xml, guix.xml).")

(defun goldayan/generate-all-rss (project)
  "Completion function to generate main RSS feed and custom tag-specific feeds."
  ;; 1. Generate main feed (feed.xml)
  (org-publish-rss project)

  ;; 2. Generate tag-specific feeds
  (let ((base-plist (cond ((stringp project)
                           (cdr (assoc project org-publish-project-alist)))
                          ((stringp (car project))
                           (cdr project))
                          (t project)))
        (proj-name (cond ((stringp project) project)
                         ((stringp (car project)) (car project))
                         (t "project"))))
    (dolist (tag goldayan/rss-custom-tags)
      (let* ((filename (format "%s.xml" tag))
             (title (format "Gold Ayan's Tinker Garage - %s" (capitalize tag)))
             (desc (format "Blog posts tagged with %s" tag))
             (filter-fn (lambda (file)
                          (and (string-match-p "/posts/" file)
                               (not (string-equal (file-name-nondirectory file) "index.org"))
                               (not (goldayan/org-file-draft-p file))
                               (goldayan/org-file-has-tag-p file tag))))
             (tag-plist (copy-sequence base-plist)))
        (setq tag-plist (plist-put tag-plist :rss-file filename))
        (setq tag-plist (plist-put tag-plist :rss-title title))
        (setq tag-plist (plist-put tag-plist :rss-description desc))
        (setq tag-plist (plist-put tag-plist :rss-filter-function filter-fn))
        (let ((tag-project (cons proj-name tag-plist)))
          (message "Generating RSS feed for tag '%s' -> %s..." tag filename)
          (org-publish-rss tag-project))))))

;; Publish feed
(setq org-publish-rss-publish-immediately t)

(setq org-publish-project-alist
      `(("goldayan:blog"
	 :recursive t
         :base-directory "./content"
         :base-extension "org"
         :publishing-directory "./public"
	 :htmlized-source t

	 :html-head-extra ,goldayan/head-extra

         :with-author nil  ;; Don't include author name
         :with-creator nil ;; Include Emacs and Org versions in footer
         :with-toc nil     ;; Include a table of contents
         :section-numbers nil ;; Don't include section numbers
	 
         :publishing-function  org-html-publish-to-html

         :html-link-home "https://goldayan.in"

         :auto-rss t
         :rss-file "feed.xml"
         :rss-title "Gold Ayan's Tinker Garage"
         :rss-description "Let’s tinker!"
         :rss-with-content all
         :rss-filter-function goldayan/rss-filter-main

         :completion-function goldayan/generate-all-rss)

	("goldayan:assets" ;; Copy all the assets - images, css and js
         :recursive t
         :base-directory "./assets"
	 :base-extension "css\\|js\\|png\\|jpg\\|gif\\|pdf\\|mp3\\|html\\|mp4\\|ico"
         :publishing-function org-publish-attachment
         :publishing-directory "./public/assets")

        ("goldayan.in" :components ("goldayan:blog" "goldayan:assets")) ))

;; Generate the site output
(org-publish-all t)

(message "Build complete!")


