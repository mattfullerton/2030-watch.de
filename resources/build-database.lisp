
;; Common Lisp code for building database.js

(in-package "CL-USER")

(eval-when (:compile-toplevel :load-toplevel :execute)
  (ql:quickload :alexandria)
  (ql:quickload :yason))

(defvar *collection* #P"/home/cpape/okf/2030-watch.de/resources/single-data-sets/online/")

(defvar *database* #P"/home/cpape/okf/2030-watch.de/js/database.js")

(defvar *template-start* "var indicators = [")

(defvar *template-end* "];")

(defun build-database ()
  (let ((jsons (uiop/filesystem:directory-files *collection*)))
    (with-open-file (out *database* :direction :output :external-format :utf-8 :if-exists :supersede)
      (format out "~&~A" *template-start*)
      (loop
         for json in jsons
         for rest on jsons
         do (with-open-file (in json :direction :input :external-format :utf-8)
              (format out "~3&")
              (uiop/stream:copy-stream-to-stream in out))
         if (rest rest) do (format out ","))
      (format out "~3&~A" *template-end*))
    (format t "~& ~A written.~%" *database*)))

(defun test-jsons ()
  (flet ((check (json)
           (with-open-file (in json :direction :input :external-format :utf-8)
             (if (ignore-errors (yason:parse in))
                 t
                 nil))))
    (let ((jsons (uiop/filesystem:directory-files *collection*)))
      (loop for json in jsons
         collect (list (pathname-name json) (check json))))))

(defun create-csv (&optional (stream *standard-output*) (path *collection*))
  (let* ((jsons (uiop/filesystem:directory-files *collection*))
         (lines (loop
                   for json in jsons
                   collect (with-open-file (in json :direction :input :external-format :utf-8)
                             (let ((parsed (yason:parse in :object-as :alist)))
                               (flet ((get-value (item)
                                        (rest (assoc item parsed :test #'equalp))))
                                 (let ((|original-title| (get-value "original-title"))
                                       (|indicator source| (get-value "indicator source"))
                                       (|source of data| (get-value "source of data"))
                                       (|sdg| (format nil "~{~A~^,~}" (get-value "sdg")))
                                       (|short indicator description_en| (get-value "short indicator description_en")))
                                   (list |original-title|
                                         |indicator source|
                                         |source of data|
                                         |sdg|
                                         |short indicator description_en|))))))))
    (loop for line in lines
       do (format stream "~&~{\"~A\"~^,~}" line))))
