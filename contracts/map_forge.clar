;; MapForge Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-owner (err u100))
(define-constant err-already-exists (err u101))
(define-constant err-not-found (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-price (err u104))
(define-constant err-invalid-rating (err u105))
(define-constant err-empty-input (err u106))

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

(define-private (validate-input (title (string-ascii 100)) (description (string-utf8 500)) (price uint))
    (and 
        (> (len title) u0)
        (> (len description) u0)
        (>= price u0)
    )
)

;; Public Functions

(define-public (create-itinerary (title (string-ascii 100)) 
                              (description (string-utf8 500))
                              (price uint)
                              (locations (list 20 (string-utf8 100)))
                              (details (string-utf8 2000)))
    (let ((itinerary-id (var-get next-itinerary-id)))
        (asserts! (validate-input title description price) (err err-empty-input))
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
        (print { event: "itinerary-created", id: itinerary-id, creator: tx-sender })
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
                (print { event: "itinerary-purchased", id: itinerary-id, buyer: tx-sender })
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
                (print { event: "itinerary-purchased", id: itinerary-id, buyer: tx-sender, price: price })
                (ok true)
            )
        )
    )
)

;; Withdraw earnings (fixed security issue)
(define-public (withdraw-earnings)
    (let (
        (earnings (default-to u0 (map-get? user-earnings tx-sender)))
    )
        (if (> earnings u0)
            (begin
                (try! (stx-transfer? earnings (as-contract tx-sender) tx-sender))
                (map-set user-earnings tx-sender u0)
                (print { event: "earnings-withdrawn", user: tx-sender, amount: earnings })
                (ok earnings)
            )
            (err u0)
        )
    )
)

;; [Rest of the contract remains unchanged]
