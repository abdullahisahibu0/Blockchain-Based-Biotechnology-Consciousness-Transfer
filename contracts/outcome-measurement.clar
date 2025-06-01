;; Outcome Measurement Contract
;; Evaluates consciousness transfer success and maintains records

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u400))
(define-constant ERR_OUTCOME_EXISTS (err u401))
(define-constant ERR_OUTCOME_NOT_FOUND (err u402))
(define-constant ERR_INVALID_SCORE (err u403))

(define-map transfer-outcomes
  { outcome-id: uint }
  {
    protocol-id: uint,
    success-rate: uint,
    memory-retention: uint,
    personality-coherence: uint,
    cognitive-function: uint,
    overall-score: uint,
    evaluation-date: uint,
    evaluator: principal,
    notes: (string-ascii 200),
    verified: bool
  }
)

(define-map success-metrics
  { protocol-id: uint }
  {
    total-attempts: uint,
    successful-transfers: uint,
    partial-successes: uint,
    failures: uint,
    average-score: uint
  }
)

(define-data-var next-outcome-id uint u1)

(define-public (record-transfer-outcome
  (protocol-id uint)
  (memory-retention uint)
  (personality-coherence uint)
  (cognitive-function uint)
  (notes (string-ascii 200))
)
  (let
    (
      (outcome-id (var-get next-outcome-id))
      (overall-score (calculate-overall-score memory-retention personality-coherence cognitive-function))
      (success-rate (determine-success-rate overall-score))
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (and (<= memory-retention u100) (<= personality-coherence u100) (<= cognitive-function u100)) ERR_INVALID_SCORE)

    (map-set transfer-outcomes
      { outcome-id: outcome-id }
      {
        protocol-id: protocol-id,
        success-rate: success-rate,
        memory-retention: memory-retention,
        personality-coherence: personality-coherence,
        cognitive-function: cognitive-function,
        overall-score: overall-score,
        evaluation-date: block-height,
        evaluator: tx-sender,
        notes: notes,
        verified: false
      }
    )

    ;; Update success metrics
    (update-success-metrics protocol-id overall-score)

    (var-set next-outcome-id (+ outcome-id u1))
    (ok outcome-id)
  )
)

(define-private (calculate-overall-score (memory uint) (personality uint) (cognitive uint))
  (/ (+ memory personality cognitive) u3)
)

(define-private (determine-success-rate (overall-score uint))
  (if (>= overall-score u90)
    u100
    (if (>= overall-score u75)
      u80
      (if (>= overall-score u60)
        u60
        u20
      )
    )
  )
)

(define-private (update-success-metrics (protocol-id uint) (score uint))
  (let
    (
      (current-metrics (default-to
        { total-attempts: u0, successful-transfers: u0, partial-successes: u0, failures: u0, average-score: u0 }
        (map-get? success-metrics { protocol-id: protocol-id })
      ))
      (new-total (+ (get total-attempts current-metrics) u1))
      (new-successful (if (>= score u90) (+ (get successful-transfers current-metrics) u1) (get successful-transfers current-metrics)))
      (new-partial (if (and (>= score u60) (< score u90)) (+ (get partial-successes current-metrics) u1) (get partial-successes current-metrics)))
      (new-failures (if (< score u60) (+ (get failures current-metrics) u1) (get failures current-metrics)))
      (new-average (/ (+ (* (get average-score current-metrics) (get total-attempts current-metrics)) score) new-total))
    )
    (map-set success-metrics
      { protocol-id: protocol-id }
      {
        total-attempts: new-total,
        successful-transfers: new-successful,
        partial-successes: new-partial,
        failures: new-failures,
        average-score: new-average
      }
    )
  )
)

(define-public (verify-outcome (outcome-id uint))
  (let ((outcome (unwrap! (map-get? transfer-outcomes { outcome-id: outcome-id }) ERR_OUTCOME_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    (map-set transfer-outcomes
      { outcome-id: outcome-id }
      (merge outcome { verified: true })
    )
    (ok true)
  )
)

(define-read-only (get-transfer-outcome (outcome-id uint))
  (map-get? transfer-outcomes { outcome-id: outcome-id })
)

(define-read-only (get-success-metrics (protocol-id uint))
  (map-get? success-metrics { protocol-id: protocol-id })
)

(define-read-only (get-overall-success-rate)
  (let
    (
      (total-protocols u10) ;; This would be calculated dynamically in a real implementation
      (successful-protocols u7) ;; This would be calculated dynamically
    )
    (if (> total-protocols u0)
      (/ (* successful-protocols u100) total-protocols)
      u0
    )
  )
)
