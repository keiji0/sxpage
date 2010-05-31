#!/usr/local/bin/gosh

(define-module sxpage
  (use gauche.parameter)
  (use util.match)
  (use file.util)
  (use srfi-13)
  (export sxpage-dispath sxpage-param fdlist)
  
  (define (make-param)
    (let ((ht (make-hash-table)))
      (lambda (message . args)
        (case message
          ((put!) (apply hash-table-put! ht args))
          ((delete!) (apply hash-table-delete! ht args))
          ((get) (apply hash-table-get ht args))
          ((push!) (apply hash-table-push! ht args))
          ((pop!) (apply hash-table-pop! ht args))
          ((update!) (apply hash-table-update! ht args))
          ((ht) ht)
          (else (error "unknow message:" message))))))

  (define sxpage-param (make-parameter (make-param)))
              
  (define (fdlist x)
    (cond ((list? x)
           (cond ((list? (car x)) x)
                 (else (list x))))
          (else
           (list x))))
  
  (define (sxpage-dispath path)

    (define (split-path path)
      (if (string=? path "/")
          (list "/")
          (map (lambda (x)
                 (cond ((string=? x "") "/")
                       (else
                        (if (string-suffix? ".html" x)
                            (string-drop-right x 5)
                            x))))
               (string-split path "/"))))

    (define (load-paths path)
      (let lp ((next path)
               (path "./")
               (result '()))
        (if (null? next)
            (reverse (map (cut string-append <> ".scm") result))
            (match next
              ((x "/")
               (lp '()
                   ""
                   (cons (build-path path x "index") result)))
              (("/" "index")
               (lp '()
                   ""
                   (cons (string-append path "index") result)))
              (("/" . rest)
               (lp rest
                   (string-append path)
                   (cons (string-append path "index") result)))
              ((x)
               (lp '()
                   ""
                   (cons (build-path path x) result)))
              ((x . rest)
               (lp rest
                   (build-path path x)
                   (cons (build-path path x "index") result)))))))

    (parameterize ((sxpage-param (make-param)))
      ((sxpage-param) 'put! 'path (split-path path))
      ((sxpage-param) 'put! 'load-path (load-paths ((sxpage-param) 'get 'path)))
      ((global-variable-ref 'sxpage.user 'init-hook values))
      (dolist (path (load-paths ((sxpage-param) 'get 'path)))
        (when (file-exists? path)
          (load path :environment (find-module 'sxpage.user))))
      (((sxpage-param) 'get 'formatter)
       (fold (lambda (x r) (x r))
             ((sxpage-param) 'get 'body)
             ((sxpage-param) 'get 'wrap '())))))
    )


(define-module sxpage.user
  (use file.util)
  (import sxpage)
  (define $p sxpage-param)
  (define $fl (global-variable-ref 'sxpage 'fdlist))
  (define ($/ . args)
    (apply build-path
           (append (map (lambda (x) "..")
                        (if (null? (cdr (($p) 'get 'path)))
                            (cdr (($p) 'get 'path))
                            (cddr (($p) 'get 'path))))
                   (if (null? args) '("") args))))
  (define (%pg name)
    (case-lambda
     (() (($p) 'get name))
     ((val) (($p) 'put! name val))))
  (define title (%pg 'title))
  (define keywords (%pg 'keywords))
  (define description (%pg 'description))
  (define encoding (%pg 'encoding))
  (define document-type (%pg 'document-type))
  (define body (%pg 'body))
  (define body-filter (%pg 'body-filter))
  (define (css-src name) (($p) 'push! 'css-src name))
  (define (css-src-pop!) (($p) 'pop! 'css-src))
  (define (css-code name) (($p) 'push! 'css-code name))
  (define (javascript-src name) (($p) 'push! 'javascript-src name))
  (define (javascript-src-pop!) (($p) 'pop! 'javascript-src))
  (define (javascript-code code) (($p) 'push! 'javascript-code code))
  (define (wrap name) (($p) 'push! 'wrap name))
  (define (top?) (null? (cdr (($p) 'get 'load-path))))
  (define ($escape string)
    (define (html-escape)
      (port-for-each (lambda (c)
                       (case c
                         ((#\<) (display "&lt;"))
                         ((#\>) (display "&gt;"))
                         ((#\&) (display "&amp;"))
                         ((#\") (display "&quot;"))
                         (else (display c))
                         ))
                     read-char))
    (with-string-io (x->string string) html-escape))
  (define (html-format body)
    (define (flist x) (if (list? x) x (list x)))
    (define p ($p))
    (define (elfor key proc) (cond ((p 'get key #f) => proc) ('())))
    (define (dis doc)
      (define (attr as)
        (dolist (x as)
          (format #t " ~a=\"~a\"" (car x) (cadr x))))
      (define (cls tag con)
        (unless (null? con) (format #t "</~a>" tag)))
      (cond ((string? doc) (display doc))
            ((and (pair? doc) (symbol? (car doc)))
             (let ((tag (car doc)))
               (format #t "<~a" tag)
               (if (and (not (null? (cdr doc)))
                        (pair? (cadr doc))
                        (eq? (caadr doc) '@))
                   (begin (attr (cdadr doc))
                          (if (null? (cddr doc)) (display " />") (display ">"))
                          (dis (cddr doc))
                          (cls tag (cddr doc)))
                   (begin (if (null? (cdr doc)) (display " />") (display ">"))
                          (dis (cdr doc))
                          (cls tag (cdr doc))))))
            ((pair? doc)
             (dis (car doc))
             (dis (cdr doc)))
            (else "")))
    (display (document-type))
    (dis `(html (@ (xmlns "http://www.w3.org/1999/xhtml")
                   (xml:lang "ja") (lang "ja"))
                (head
                 (meta (@ (http-equiv "Content-Type") (content ,#`"text/html; charset=,(encoding)")))
                 (title ,(p 'get 'title "no title"))
                 ,@(elfor 'keywords (lambda (k) `((meta (@ (name "keywords") (content ,k))))))
                 ,@(elfor 'description (lambda (k) `((meta (@ (name "description") (content ,k))))))
                 ,@(elfor 'next-link (lambda (k) `((link (@ (rel "next") (href ,k) (title ,(p 'get 'next-link-title "")))))))
                 ,@(elfor 'prev-link (lambda (k) `((link (@ (rel "prev") (href ,k) (title ,(p 'get 'prev-link-title "")))))))
                 ,@(elfor 'contents-link (lambda (k) `((link (@ (rel "contents") (href ,k) (title ,(p 'get 'contents-link-title "")))))))
                 ,@(elfor 'index-link (lambda (k) `((link (@ (rel "index") (href ,k) (title ,(p 'get 'index-link-title "")))))))
                 (meta (@ (http-equiv "Content-Style-Type") (content "text/css")))
                 (meta (@ (http-equiv "Content-Script-Type") (content "text/javascript")))
                 ,@(map (lambda (x) `(link (@ (rel "stylesheet") (href ,x) (type "text/css")))) (flist (p 'get 'css-src '())))
                 ,@(map (lambda (x) `(style (@ (type "text/css")) ,x)) (flist (p 'get 'css-code '())))
                 ,@(map (lambda (x) `(script (@ (type "text/javascript") (src ,x)))) (reverse (flist (p 'get 'javascript-src '()))))
                 ,@(map (lambda (x) `(script (@ (type "text/javascript")) "\n//<![CDATA[\n" ,x "\n//]]>\n")) (flist (p 'get 'javascript-code '()))))
                (body (@ ,@(elfor 'onload (lambda (x) `(onload ,x))))
                      ,@(fdlist (cond ((p 'get 'body-filter #f) => (cut <> body))
                                      (else body))))
                )))
  (define (init-hook)
    (document-type "<?xml version=\"1.0\" encoding=\"utf-8\"?>
<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">")
    (encoding "utf-8")
    (($p) 'put! 'formatter html-format))
  )

(import sxpage)
(use www.cgi)
(use gauche.parameter)

(define (main args)
  (define (web-cgi?) (cgi-get-metavariable "REQUEST_METHOD"))
  (define (get-path-info) (if (web-cgi?)
                              (cgi-get-metavariable "PATH_INFO")
                              (x->string (cadr args))))
  (parameterize ((cgi-metavariables `(("PATH_INFO" ,(get-path-info)))))
    (let ((path-info (cgi-get-metavariable "PATH_INFO")))
      (if (web-cgi?)
          (cgi-main
           (lambda (params)
             `(,(cgi-header)
               ,(with-output-to-string (cut sxpage-dispath path-info)))))
          (let ((path (cadr args)))
            (sxpage-dispath path-info)))
      0)))