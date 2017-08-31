;;; ob-aql.el --- org-babel functions for arangodb query language

;; Copyright (C) 2017 Feng Zhou

;; Author: Feng Zhou <zf.pascal@gmail.com>
;; URL: http://github.com/zweifisch/ob-aql
;; Keywords: org babel aql
;; Version: 0.0.1
;; Created: 31th Aug 2017
;; Package-Requires: ((org "8"))

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; org-babel functions for arangodb query language
;;

;;; Code:
(require 'ob)
(require 'json)


(defun org-babel-execute:aql (body params)
  (let* ((user (cdr (assoc :user params)))
         (password (cdr (assoc :password params)))
         (host (or (cdr (assoc :host params)) "localhost"))
         (port (or (cdr (assoc :port params)) 8529))
         (database (or (cdr (assoc :database params)) "_system"))
         (explain (assoc :explain params))
         (url (format "http://%s:%s@%s:%s/_db/%s/_api" user password host port database)))
    (if explain
        (ob-aql--prettify-explain
         (ob-aql--query (concat url "/explain") body))
      (ob-aql--prettify
       (ob-aql--query (concat url "/cursor") body)))))

(defun ob-aql--prettify (resp)
  (let* ((resp (json-read-from-string resp))
         (err (assoc-default 'error resp))
         (msg (assoc-default 'errorMessage resp))
         (result (assoc-default 'result resp)))
    (if (eq t err)
        msg
      (ob-aql--prettify-json (json-encode result)))))

(defun ob-aql--prettify-json (string)
  (with-temp-buffer
    (insert string)
    (json-pretty-print-buffer)
    (buffer-string)))

(defun ob-aql--prettify-explain (resp)
  (let* ((resp (json-read-from-string resp)))
    (ob-aql--prettify-json (json-encode resp))))

(defun ob-aql--query (url body)
  (let ((query (json-encode `((query . ,body)))))
    (with-temp-buffer
      (insert query)
      (shell-command-on-region (point-min) (point-max) (format "curl -sd @- %s" url) nil 't)
      (buffer-string))))

(provide 'ob-aql)
;;; ob-aql.el ends here
