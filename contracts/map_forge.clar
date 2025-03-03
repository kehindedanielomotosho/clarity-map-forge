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
(define-constant err-empty-locations (err u107))
(define-constant err-empty-details (err u108))
(define-constant max-price u1000000000) ;; 1B STX maximum price

;; [Previous data variables and maps remain unchanged]

;; Private Functions
(define-private (validate-rating (rating uint))
    (and (>= rating u1) (<= rating u5))
)

(define-private (validate-input (title (string-ascii 100)) (description (string-utf8 500)) (price uint))
    (and 
        (> (len title) u0)
        (> (len description) u0)
        (and (>= price u0) (<= price max-price))
    )
)

(define-public (create-itinerary (title (string-ascii 100)) 
                              (description (string-utf8 500))
                              (price uint)
                              (locations (list 20 (string-utf8 100)))
                              (details (string-utf8 2000)))
    (let ((itinerary-id (var-get next-itinerary-id)))
        (asserts! (validate-input title description price) (err err-empty-input))
        (asserts! (> (len locations) u0) (err err-empty-locations))
        (asserts! (> (len details) u0) (err err-empty-details))
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

;; Withdraw earnings (fixed security issue - follows CEI pattern)
(define-public (withdraw-earnings)
    (let (
        (earnings (default-to u0 (map-get? user-earnings tx-sender)))
    )
        (asserts! (> earnings u0) (err u0))
        ;; Effects before interaction
        (map-set user-earnings tx-sender u0)
        ;; Interaction last
        (try! (stx-transfer? earnings (as-contract tx-sender) tx-sender))
        (print { event: "earnings-withdrawn", user: tx-sender, amount: earnings })
        (ok earnings)
    )
)

;; [Rest of the contract remains unchanged]
