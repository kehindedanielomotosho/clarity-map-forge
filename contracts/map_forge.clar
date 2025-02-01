;; MapForge Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-owner (err u100))
(define-constant err-already-exists (err u101))
(define-constant err-not-found (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-price (err u104))
(define-constant err-invalid-rating (err u105))

;; Data Variables
(define-data-var next-itinerary-id uint u0)

;; Data Maps
(define-map itineraries
    uint
    {
        owner: principal,
        title: (string-ascii 100),
        description: (string-utf8 500),
        price: uint,
        active: bool,
        created-at: uint
    }
)

(define-map itinerary-content
    uint 
    {
        locations: (list 20 (string-utf8 100)),
        details: (string-utf8 2000)
    }
)

(define-map itinerary-purchases
    { itinerary-id: uint, user: principal }
    { purchased: bool }
)

(define-map user-earnings
    principal
    uint
)

(define-map itinerary-ratings
    { itinerary-id: uint, user: principal }
    { rating: uint, review: (string-utf8 500) }
)

;; Private Functions
(define-private (validate-rating (rating uint))
    (and (>= rating u1) (<= rating u5))
)

;; Public Functions

;; Create new itinerary
(define-public (create-itinerary (title (string-ascii 100)) 
                                (description (string-utf8 500))
                                (price uint)
                                (locations (list 20 (string-utf8 100)))
                                (details (string-utf8 2000)))
    (let ((itinerary-id (var-get next-itinerary-id)))
        (asserts! (> (len locations) u0) (err err-invalid-price))
        (map-insert itineraries 
            itinerary-id
            {
                owner: tx-sender,
                title: title,
                description: description,
                price: price,
                active: true,
                created-at: block-height
            }
        )
        (map-insert itinerary-content
            itinerary-id
            {
                locations: locations,
                details: details
            }
        )
        (var-set next-itinerary-id (+ itinerary-id u1))
        (ok itinerary-id)
    )
)

;; Purchase access to itinerary
(define-public (purchase-itinerary (itinerary-id uint))
    (let (
        (itinerary (unwrap! (map-get? itineraries itinerary-id) (err err-not-found)))
        (price (get price itinerary))
    )
        (asserts! (get active itinerary) (err err-unauthorized))
        (if (is-eq price u0)
            (begin
                (map-set itinerary-purchases 
                    { itinerary-id: itinerary-id, user: tx-sender }
                    { purchased: true }
                )
                (ok true)
            )
            (begin
                (try! (stx-transfer? price tx-sender (get owner itinerary)))
                (map-set itinerary-purchases 
                    { itinerary-id: itinerary-id, user: tx-sender }
                    { purchased: true }
                )
                (map-set user-earnings 
                    (get owner itinerary)
                    (+ (default-to u0 (map-get? user-earnings (get owner itinerary))) price)
                )
                (ok true)
            )
        )
    )
)

;; Rate and review itinerary
(define-public (rate-itinerary (itinerary-id uint) (rating uint) (review (string-utf8 500)))
    (let (
        (purchase-record (unwrap! (map-get? itinerary-purchases { itinerary-id: itinerary-id, user: tx-sender }) (err err-unauthorized)))
    )
        (asserts! (validate-rating rating) (err err-invalid-rating))
        (if (get purchased purchase-record)
            (begin
                (map-set itinerary-ratings
                    { itinerary-id: itinerary-id, user: tx-sender }
                    { rating: rating, review: review }
                )
                (ok true)
            )
            (err err-unauthorized)
        )
    )
)

;; Withdraw earnings
(define-public (withdraw-earnings)
    (let (
        (earnings (default-to u0 (map-get? user-earnings tx-sender)))
    )
        (if (> earnings u0)
            (begin
                (try! (as-contract (stx-transfer? earnings contract-owner tx-sender)))
                (map-set user-earnings tx-sender u0)
                (ok earnings)
            )
            (err u0)
        )
    )
)

;; Read-only functions

(define-read-only (get-itinerary (itinerary-id uint))
    (map-get? itineraries itinerary-id)
)

(define-read-only (get-itinerary-content (itinerary-id uint))
    (let (
        (purchase-record (map-get? itinerary-purchases { itinerary-id: itinerary-id, user: tx-sender }))
        (itinerary (map-get? itineraries itinerary-id))
    )
        (if (or 
            (is-eq tx-sender (get owner itinerary))
            (get purchased (default-to { purchased: false } purchase-record))
        )
            (map-get? itinerary-content itinerary-id)
            none
        )
    )
)

(define-read-only (get-user-earnings (user principal))
    (default-to u0 (map-get? user-earnings user))
)
