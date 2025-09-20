;; title: RecognitionVote
;; version: 1.0
;; summary: A transparent platform for industry honors and professional achievement awards
;; description: This contract enables organizations to create awards, nominate candidates,
;;              and conduct transparent voting for industry recognition and professional achievements.

;; traits
;;

;; token definitions
;;

;; constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-invalid-status (err u104))
(define-constant err-voting-closed (err u105))
(define-constant err-already-voted (err u106))
(define-constant err-invalid-period (err u107))

;; Award status constants
(define-constant status-open u1)
(define-constant status-voting u2)
(define-constant status-closed u3)

;; data vars
(define-data-var next-award-id uint u1)
(define-data-var next-nomination-id uint u1)

;; data maps
;; Awards storage
(define-map awards
  uint
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    category: (string-ascii 50),
    creator: principal,
    nomination-start: uint,
    nomination-end: uint,
    voting-start: uint,
    voting-end: uint,
    status: uint,
    total-votes: uint,
    winner: (optional uint)
  }
)

;; Nominations storage
(define-map nominations
  uint
  {
    award-id: uint,
    nominee-name: (string-ascii 100),
    nominee-description: (string-ascii 500),
    nominator: principal,
    vote-count: uint,
    created-at: uint
  }
)

;; Track votes to prevent double voting
(define-map votes
  {voter: principal, nomination-id: uint}
  bool
)

;; Award creators/organizers
(define-map award-organizers
  principal
  bool
)

;; Nominee verification (optional - for verified nominees)
(define-map verified-nominees
  principal
  {
    name: (string-ascii 100),
    verified: bool
  }
)

;; public functions

;; Add organizer (only contract owner)
(define-public (add-organizer (organizer principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (map-set award-organizers organizer true))
  )
)

;; Remove organizer (only contract owner)
(define-public (remove-organizer (organizer principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (map-delete award-organizers organizer))
  )
)

;; Create new award
(define-public (create-award
    (title (string-ascii 100))
    (description (string-ascii 500))
    (category (string-ascii 50))
    (nomination-start uint)
    (nomination-end uint)
    (voting-start uint)
    (voting-end uint))
  (let
    (
      (award-id (var-get next-award-id))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (or (is-eq tx-sender contract-owner)
                  (default-to false (map-get? award-organizers tx-sender))) err-unauthorized)
    (asserts! (< nomination-start nomination-end) err-invalid-period)
    (asserts! (< nomination-end voting-start) err-invalid-period)
    (asserts! (< voting-start voting-end) err-invalid-period)

    (map-set awards award-id {
      title: title,
      description: description,
      category: category,
      creator: tx-sender,
      nomination-start: nomination-start,
      nomination-end: nomination-end,
      voting-start: voting-start,
      voting-end: voting-end,
      status: status-open,
      total-votes: u0,
      winner: none
    })

    (var-set next-award-id (+ award-id u1))
    (ok award-id)
  )
)

;; Nominate candidate for award
(define-public (nominate
    (award-id uint)
    (nominee-name (string-ascii 100))
    (nominee-description (string-ascii 500)))
  (let
    (
      (nomination-id (var-get next-nomination-id))
      (award (unwrap! (map-get? awards award-id) err-not-found))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (>= current-time (get nomination-start award)) err-invalid-status)
    (asserts! (<= current-time (get nomination-end award)) err-invalid-status)
    (asserts! (is-eq (get status award) status-open) err-invalid-status)

    (map-set nominations nomination-id {
      award-id: award-id,
      nominee-name: nominee-name,
      nominee-description: nominee-description,
      nominator: tx-sender,
      vote-count: u0,
      created-at: current-time
    })

    (var-set next-nomination-id (+ nomination-id u1))
    (ok nomination-id)
  )
)

;; Start voting phase for an award
(define-public (start-voting (award-id uint))
  (let
    (
      (award (unwrap! (map-get? awards award-id) err-not-found))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (is-eq tx-sender (get creator award)) err-unauthorized)
    (asserts! (>= current-time (get voting-start award)) err-invalid-status)
    (asserts! (is-eq (get status award) status-open) err-invalid-status)

    (map-set awards award-id
      (merge award {status: status-voting}))
    (ok true)
  )
)

;; Vote for a nomination
(define-public (vote (nomination-id uint))
  (let
    (
      (nomination (unwrap! (map-get? nominations nomination-id) err-not-found))
      (award-id (get award-id nomination))
      (award (unwrap! (map-get? awards award-id) err-not-found))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
      (vote-key {voter: tx-sender, nomination-id: nomination-id})
    )
    (asserts! (>= current-time (get voting-start award)) err-voting-closed)
    (asserts! (<= current-time (get voting-end award)) err-voting-closed)
    (asserts! (is-eq (get status award) status-voting) err-voting-closed)
    (asserts! (is-none (map-get? votes vote-key)) err-already-voted)

    ;; Record the vote
    (map-set votes vote-key true)

    ;; Update nomination vote count
    (map-set nominations nomination-id
      (merge nomination {vote-count: (+ (get vote-count nomination) u1)}))

    ;; Update total votes for award
    (map-set awards award-id
      (merge award {total-votes: (+ (get total-votes award) u1)}))

    (ok true)
  )
)

;; Close voting and determine winner
(define-public (close-voting (award-id uint))
  (let
    (
      (award (unwrap! (map-get? awards award-id) err-not-found))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (is-eq tx-sender (get creator award)) err-unauthorized)
    (asserts! (>= current-time (get voting-end award)) err-invalid-status)
    (asserts! (is-eq (get status award) status-voting) err-invalid-status)

    (map-set awards award-id
      (merge award {
        status: status-closed,
        winner: (get-winner award-id)
      }))
    (ok true)
  )
)

;; read only functions

;; Get award details
(define-read-only (get-award (award-id uint))
  (map-get? awards award-id)
)

;; Get nomination details
(define-read-only (get-nomination (nomination-id uint))
  (map-get? nominations nomination-id)
)

;; Check if user has voted for a nomination
(define-read-only (has-voted (voter principal) (nomination-id uint))
  (default-to false (map-get? votes {voter: voter, nomination-id: nomination-id}))
)

;; Check if user is an organizer
(define-read-only (is-organizer (user principal))
  (default-to false (map-get? award-organizers user))
)

;; Get award status
(define-read-only (get-award-status (award-id uint))
  (match (map-get? awards award-id)
    award (some (get status award))
    none
  )
)

;; Get current award and nomination IDs
(define-read-only (get-next-ids)
  {
    next-award-id: (var-get next-award-id),
    next-nomination-id: (var-get next-nomination-id)
  }
)

;; Check if award is in voting phase
(define-read-only (is-voting-active (award-id uint))
  (match (map-get? awards award-id)
    award (and
      (is-eq (get status award) status-voting)
      (let ((current-time (default-to u0 (get-block-info? time (- block-height u1)))))
        (and
          (>= current-time (get voting-start award))
          (<= current-time (get voting-end award)))))
    false
  )
)

;; Check if nominations are open
(define-read-only (is-nomination-active (award-id uint))
  (match (map-get? awards award-id)
    award (and
      (is-eq (get status award) status-open)
      (let ((current-time (default-to u0 (get-block-info? time (- block-height u1)))))
        (and
          (>= current-time (get nomination-start award))
          (<= current-time (get nomination-end award)))))
    false
  )
)

;; private functions

;; Helper function to find winner (nomination with most votes)
(define-private (get-winner (award-id uint))
  ;; This is a simplified implementation
  ;; In a full implementation, you'd iterate through all nominations for this award
  ;; For now, returns none - can be enhanced based on specific requirements
  none
)

;; Get contract owner
(define-read-only (get-contract-owner)
  contract-owner
)