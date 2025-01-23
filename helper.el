(defun convert-html-elisp-string ();;(buffer-name)
  ""
  (interactive)
  ;; Switch to the particular buffer and perform the operation
  ;;(switch-to-buffer-other-window buffer-name)

  (goto-char (point-min))       ; Move to the beginning of the buffer
  (replace-string "\"" "\\\"")  ; Replace " with \"

  (goto-char (point-min))       ; Move to the beginning of the buffer
  (while (not (eobp))  ; While not at the end of the buffer

    ;; If current line is empty then move to next line
    (if (= (current-indentation)
	   (- (line-end-position) (line-beginning-position)))
	(forward-line 1)
      )
    
    (back-to-indentation) ;; Move to first non whitespace character
    (insert "\"" )  ; Insert a quote at the beginning of the line
    (end-of-line)
    (insert "\"")
    (forward-line 1))

  ;; Just for fun - add concat in function infront of the data
  (goto-char (point-min))
  (insert "(concat ")
  (goto-char (point-max))
  (insert ")")  
  )

;; Usage
;; (convert-html-elisp-string "template.html")
