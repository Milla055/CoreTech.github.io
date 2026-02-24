package com.mycompany.coretech3.service;


import java.util.List;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;

@Stateless
public class AnalyticsService {

    @PersistenceContext(unitName = "com.mycompany_coreTech3_war_1.0-SNAPSHOTPU")
    private EntityManager em;

    public long getTotalRevenue() {
        Object result = em.createNativeQuery(
                "SELECT SUM(oi.quantity * p.price) "
                + "FROM order_items oi "
                + "JOIN products p ON p.id = oi.product_id"
        ).getSingleResult();

        if (result == null) {
            return 0;
        }

        return ((Number) result).longValue();
    }

    public long getTotalProfit() {
        Object result = em.createNativeQuery(
                "SELECT SUM(oi.quantity * (p.price - p.p_price)) "
                + "FROM order_items oi "
                + "JOIN products p ON p.id = oi.product_id"
        ).getSingleResult();

        if (result == null) {
            return 0;
        }

        return ((Number) result).longValue();
    }

    public List<Object[]> getUserSpendings() {
        return em.createNativeQuery(
                "SELECT "
                + "u.id, u.username, u.email, "
                + "COALESCE(SUM(oi.quantity * p.price), 0) AS total_spent "
                + "FROM users u "
                + "LEFT JOIN orders o ON o.user_id = u.id "
                + "LEFT JOIN order_items oi ON oi.order_id = o.id "
                + "LEFT JOIN products p ON p.id = oi.product_id "
                + "WHERE u.is_deleted = 0 OR u.is_deleted IS NULL "
                + "GROUP BY u.id, u.username, u.email"
        ).getResultList();
    }

    public long getTotalOrdersCount() {
        Object result = em.createNativeQuery(
                "SELECT COUNT(*) FROM orders"
        ).getSingleResult();

        return ((Number) result).longValue();
    }

    public List<Object[]> getOrderStatusDistribution() {
        return em.createNativeQuery(
                "SELECT status, COUNT(*) "
                + "FROM orders "
                + "GROUP BY status"
        ).getResultList();
    }
}
