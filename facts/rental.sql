WITH TimeRentals AS (
    SELECT dt.DIM_TEMPO_SEQ_TEMPO,
           f.FILM_ID,
           cat.CATEGORY_ID,
           s.STAFF_ID,
           a.ACTOR_ID,
           ad.ADDRESS_ID,
           COUNT(r.rental_id) AS Total_Rentals,
           SUM(p.amount) AS Total_Amount
    FROM DIM_TEMPO dt
    LEFT JOIN rental r ON (
        (dt.DIM_TEMPO_MES IS NULL AND YEAR(r.rental_date) = dt.DIM_TEMPO_ANO)
        OR (dt.DIM_TEMPO_MES IS NOT NULL AND YEAR(r.rental_date) = dt.DIM_TEMPO_ANO AND MONTH(r.rental_date) = dt.DIM_TEMPO_MES)
    )
    LEFT JOIN inventory i ON r.inventory_id = i.inventory_id
    LEFT JOIN film f ON i.film_id = f.film_id
    LEFT JOIN film_category fc ON f.film_id = fc.film_id
    LEFT JOIN category cat ON fc.category_id = cat.category_id
    LEFT JOIN payment p ON r.rental_id = p.rental_id
    LEFT JOIN staff s ON r.staff_id = s.staff_id
    LEFT JOIN address ad ON s.address_id = ad.address_id
    LEFT JOIN DIM_ADDRESS da ON ad.address_id = da.ADDRESS_ID
    LEFT JOIN film_actor fa ON f.film_id = fa.film_id
    LEFT JOIN actor a ON fa.actor_id = a.actor_id
    GROUP BY dt.DIM_TEMPO_SEQ_TEMPO, f.FILM_ID, cat.CATEGORY_ID, s.STAFF_ID, a.ACTOR_ID, ad.ADDRESS_ID
)

SELECT
    dt.DIM_TEMPO_SEQ_TEMPO,
    f.FILM_ID,
    cat.CATEGORY_ID,
    s.STAFF_ID,
    a.ACTOR_ID,
    ad.ADDRESS_ID,
    COALESCE(tr.Total_Rentals, 0) AS Total_Rentals,
    COALESCE(tr.Total_Amount, 0) AS Total_Amount
FROM DIM_TEMPO dt
LEFT JOIN DIM_FILM f ON 1 = 1 
LEFT JOIN DIM_CATEGORY cat ON 1 = 1 
LEFT JOIN DIM_STAFF s ON 1 = 1 
LEFT JOIN DIM_ACTOR a ON 1 = 1 
LEFT JOIN DIM_ADDRESS ad ON 1 = 1
LEFT JOIN TimeRentals tr ON dt.DIM_TEMPO_SEQ_TEMPO = tr.DIM_TEMPO_SEQ_TEMPO
                        AND f.FILM_ID = tr.FILM_ID
                        AND cat.CATEGORY_ID = tr.CATEGORY_ID
                        AND s.STAFF_ID = tr.STAFF_ID
                        AND a.ACTOR_ID = tr.ACTOR_ID
                        AND ad.ADDRESS_ID = tr.ADDRESS_ID
ORDER BY dt.DIM_TEMPO_SEQ_TEMPO, f.FILM_ID, cat.CATEGORY_ID, s.STAFF_ID, a.ACTOR_ID, ad.ADDRESS_ID;
