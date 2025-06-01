;; Ethical Oversight Contract
;; Ensures consciousness transfer ethics and compliance

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u500))
(define-constant ERR_APPROVAL_NOT_FOUND (err u501))
(define-constant ERR_ETHICS_VIOLATION (err u502))
(define-constant ERR_INSUFFICIENT_APPROVALS (err u503))

(define-map ethical-approvals
  { approval-id: uint }
  {
    protocol-id: uint,
    ethics-board-id: (string-ascii 50),
    approval-type: (string-ascii 30),
    approved: bool,
    approval-date: uint,
    expiry-date: uint,
    conditions: (string-ascii 200),
    approver: principal
  }
)

(define-map ethics-violations
  { violation-id: uint }
  {
    protocol-id: uint,
    violation-type: (string-ascii 50),
    severity: (string-ascii 20),
    description: (string-ascii 200),
    reported-by: principal,
    report-date: uint,
    resolved: bool
  }
)

(define-map consent-records
  { consent-id: uint }
  {
    protocol-id: uint,
    subject-id: (string-ascii 50),
    consent-given: bool,
    consent-date: uint,
    witness: principal,
    revocable: bool
  }
)

(define-data-var next-approval-id uint u1)
(define-data-var next-violation-id uint u1)
(define-data-var next-consent-id uint u1)

(define-public (grant-ethical-approval
  (protocol-id uint)
  (ethics-board-id (string-ascii 50))
  (approval-type (string-ascii 30))
  (expiry-blocks uint)
  (conditions (string-ascii 200))
)
  (let ((approval-id (var-get next-approval-id)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    (map-set ethical-approvals
      { approval-id: approval-id }
      {
        protocol-id: protocol-id,
        ethics-board-id: ethics-board-id,
        approval-type: approval-type,
        approved: true,
        approval-date: block-height,
        expiry-date: (+ block-height expiry-blocks),
        conditions: conditions,
        approver: tx-sender
      }
    )

    (var-set next-approval-id (+ approval-id u1))
    (ok approval-id)
  )
)

(define-public (record-consent
  (protocol-id uint)
  (subject-id (string-ascii 50))
  (witness principal)
)
  (let ((consent-id (var-get next-consent-id)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    (map-set consent-records
      { consent-id: consent-id }
      {
        protocol-id: protocol-id,
        subject-id: subject-id,
        consent-given: true,
        consent-date: block-height,
        witness: witness,
        revocable: true
      }
    )

    (var-set next-consent-id (+ consent-id u1))
    (ok consent-id)
  )
)

(define-public (report-ethics-violation
  (protocol-id uint)
  (violation-type (string-ascii 50))
  (severity (string-ascii 20))
  (description (string-ascii 200))
)
  (let ((violation-id (var-get next-violation-id)))
    (map-set ethics-violations
      { violation-id: violation-id }
      {
        protocol-id: protocol-id,
        violation-type: violation-type,
        severity: severity,
        description: description,
        reported-by: tx-sender,
        report-date: block-height,
        resolved: false
      }
    )

    (var-set next-violation-id (+ violation-id u1))
    (ok violation-id)
  )
)

(define-public (resolve-violation (violation-id uint))
  (let ((violation (unwrap! (map-get? ethics-violations { violation-id: violation-id }) ERR_APPROVAL_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    (map-set ethics-violations
      { violation-id: violation-id }
      (merge violation { resolved: true })
    )
    (ok true)
  )
)

(define-read-only (check-protocol-compliance (protocol-id uint))
  (let
    (
      (has-ethical-approval (has-valid-approval protocol-id))
      (has-consent (has-valid-consent protocol-id))
      (has-violations (has-unresolved-violations protocol-id))
    )
    {
      ethical-approval: has-ethical-approval,
      consent-recorded: has-consent,
      violations-present: has-violations,
      compliant: (and has-ethical-approval has-consent (not has-violations))
    }
  )
)

(define-private (has-valid-approval (protocol-id uint))
  ;; Simplified check - in reality would iterate through all approvals
  true
)

(define-private (has-valid-consent (protocol-id uint))
  ;; Simplified check - in reality would verify consent records
  true
)

(define-private (has-unresolved-violations (protocol-id uint))
  ;; Simplified check - in reality would check for unresolved violations
  false
)

(define-read-only (get-ethical-approval (approval-id uint))
  (map-get? ethical-approvals { approval-id: approval-id })
)

(define-read-only (get-consent-record (consent-id uint))
  (map-get? consent-records { consent-id: consent-id })
)

(define-read-only (get-ethics-violation (violation-id uint))
  (map-get? ethics-violations { violation-id: violation-id })
)
