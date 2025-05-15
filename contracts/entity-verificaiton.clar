;; Entity Verification Contract
;; Validates supply chain participants

(define-data-var contract-owner principal tx-sender)

;; Entity types: 1=Supplier, 2=Manufacturer, 3=Distributor, 4=Retailer
(define-map entities
  { entity-id: (string-ascii 32) }
  {
    principal: principal,
    name: (string-ascii 64),
    entity-type: uint,
    verified: bool,
    active: bool
  }
)

(define-read-only (get-entity (entity-id (string-ascii 32)))
  (map-get? entities { entity-id: entity-id })
)

(define-read-only (is-verified (entity-id (string-ascii 32)))
  (default-to false (get verified (get-entity entity-id)))
)

(define-public (register-entity
    (entity-id (string-ascii 32))
    (name (string-ascii 64))
    (entity-type uint))
  (begin
    (asserts! (< entity-type u5) (err u1)) ;; Valid entity type
    (asserts! (is-none (get-entity entity-id)) (err u2)) ;; Entity ID not taken
    (ok (map-set entities
      { entity-id: entity-id }
      {
        principal: tx-sender,
        name: name,
        entity-type: entity-type,
        verified: false,
        active: true
      }
    ))
  )
)

(define-public (verify-entity (entity-id (string-ascii 32)))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u3)) ;; Only owner can verify
    (match (get-entity entity-id)
      entity (ok (map-set entities
                  { entity-id: entity-id }
                  (merge entity { verified: true })))
      (err u4) ;; Entity not found
    )
  )
)

(define-public (deactivate-entity (entity-id (string-ascii 32)))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u3)) ;; Only owner can deactivate
    (match (get-entity entity-id)
      entity (ok (map-set entities
                  { entity-id: entity-id }
                  (merge entity { active: false })))
      (err u4) ;; Entity not found
    )
  )
)

(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u3))
    (ok (var-set contract-owner new-owner))
  )
)
