package com.mycompany.coretech3.service;

import java.util.List;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;

@Stateless
public class AnalyticsService {

    @PersistenceContext(unitName = "com.mycompany_coreTech3_war_1.0-SNAPSHOTPU")
    private EntityManager em;

    /**
     * Összes bevétel (revenue) - amit a vásárlók fizettek
     * Csak a befejezett/fizetett rendeléseket számoljuk
     */
    public long getTotalRevenue() {
        Object result = em.createNativeQuery(
            "SELECT COALESCE(SUM(oi.quantity * p.price), 0) " +
            "FROM order_items oi " +
            "JOIN products p ON p.id = oi.product_id " +
            "JOIN orders o ON o.id = oi.order_id "
        ).getSingleResult();

        if (result == null) {
            return 0;
        }

        return ((Number) result).longValue();
    }

    /**
     * Összes profit - (eladási ár - beszerzési ár) * mennyiség
     * price = eladási ár, p_price = beszerzési ár
     */
    public long getTotalProfit() {
        Object result = em.createNativeQuery(
            "SELECT COALESCE(SUM(oi.quantity * (p.price - p.p_price)), 0) " +
            "FROM order_items oi " +
            "JOIN products p ON p.id = oi.product_id " +
            "JOIN orders o ON o.id = oi.order_id "
        ).getSingleResult();

        if (result == null) {
            return 0;
        }

        return ((Number) result).longValue();
    }

    /**
     * Felhasználók költései - minden user-hez az összes rendelésének értéke
     */
    public List<Object[]> getUserSpendings() {
        return em.createNativeQuery(
            "SELECT " +
            "u.id, " +
            "u.username, " +
            "u.email, " +
            "COALESCE(SUM(oi.quantity * p.price), 0) AS total_spent " +
            "FROM users u " +
            "LEFT JOIN orders o ON o.user_id = u.id " +
            "LEFT JOIN order_items oi ON oi.order_id = o.id " +
            "LEFT JOIN products p ON p.id = oi.product_id " +
            "WHERE (u.is_deleted = 0 OR u.is_deleted IS NULL) " +
            "GROUP BY u.id, u.username, u.email " +
            "ORDER BY total_spent DESC"
        ).getResultList();
    }

    /**
     * Összes rendelés száma
     */
    public long getTotalOrdersCount() {
        Object result = em.createNativeQuery(
            "SELECT COUNT(*) FROM orders"
        ).getSingleResult();

        return ((Number) result).longValue();
    }

    /**
     * Rendelések státusz szerinti bontása
     */
    public List<Object[]> getOrderStatusDistribution() {
        return em.createNativeQuery(
            "SELECT status, COUNT(*) " +
            "FROM orders " +
            "GROUP BY status " +
            "ORDER BY COUNT(*) DESC"
        ).getResultList();
    }

    /**
     * Havi értékesítési statisztika - diagramhoz
     * Visszaadja: hónap, év, bevétel (Ft-ban), rendelések száma
     */
    public List<Object[]> getMonthlySalesStats() {
        return em.createNativeQuery(
            "SELECT " +
            "MONTH(o.created_at) AS month, " +
            "YEAR(o.created_at) AS year, " +
            "COALESCE(SUM(oi.quantity * p.price), 0) AS revenue, " +
            "COUNT(DISTINCT o.id) AS order_count " +
            "FROM orders o " +
            "LEFT JOIN order_items oi ON oi.order_id = o.id " +
            "LEFT JOIN products p ON p.id = oi.product_id " +
            "WHERE YEAR(o.created_at) = YEAR(CURDATE()) " +
            "GROUP BY YEAR(o.created_at), MONTH(o.created_at) " +
            "ORDER BY YEAR(o.created_at), MONTH(o.created_at)"
        ).getResultList();
    }

    /**
     * Havi profit statisztika - diagramhoz
     */
    public List<Object[]> getMonthlyProfitStats() {
        return em.createNativeQuery(
            "SELECT " +
            "MONTH(o.created_at) AS month, " +
            "YEAR(o.created_at) AS year, " +
            "COALESCE(SUM(oi.quantity * (p.price - p.p_price)), 0) AS profit " +
            "FROM orders o " +
            "LEFT JOIN order_items oi ON oi.order_id = o.id " +
            "LEFT JOIN products p ON p.id = oi.product_id " +
            "WHERE YEAR(o.created_at) = YEAR(CURDATE()) " +
            "GROUP BY YEAR(o.created_at), MONTH(o.created_at) " +
            "ORDER BY YEAR(o.created_at), MONTH(o.created_at)"
        ).getResultList();
    }

    /**
     * Regisztrált felhasználók száma (nem törölt)
     */
    public long getTotalCustomers() {
        Object result = em.createNativeQuery(
            "SELECT COUNT(*) FROM users WHERE (is_deleted = 0 OR is_deleted IS NULL)"
        ).getSingleResult();
        
        return ((Number) result).longValue();
    }

    /**
     * Összes vásárlás/rendelés száma
     */
    public long getTotalPurchases() {
        Object result = em.createNativeQuery(
            "SELECT COUNT(*) FROM orders"
        ).getSingleResult();
        
        return ((Number) result).longValue();
    }

    /**
     * Top termékek eladás alapján
     */
    public List<Object[]> getTopProducts() {
        return em.createNativeQuery(
            "SELECT " +
            "p.id, " +
            "p.name, " +
            "SUM(oi.quantity) AS total_sold, " +
            "COALESCE(SUM(oi.quantity * p.price), 0) AS total_revenue " +
            "FROM products p " +
            "JOIN order_items oi ON oi.product_id = p.id " +
            "JOIN orders o ON o.id = oi.order_id " +
            "WHERE o.status IN ('delivered', 'paid', 'completed', 'shipped') " +
            "GROUP BY p.id, p.name " +
            "ORDER BY total_sold DESC " +
            "LIMIT 10"
        ).getResultList();
    }

    /**
     * Dashboard summary - minden fontos adat egyben
     */
    public Object[] getDashboardSummary() {
        Object result = em.createNativeQuery(
            "SELECT " +
            "(SELECT COUNT(*) FROM users WHERE (is_deleted = 0 OR is_deleted IS NULL)) AS total_customers, " +
            "(SELECT COUNT(*) FROM orders) AS total_orders, " +
            "(SELECT COALESCE(SUM(oi.quantity * p.price), 0) " +
            " FROM order_items oi " +
            " JOIN products p ON p.id = oi.product_id " +
            " JOIN orders o ON o.id = oi.order_id " +
            " WHERE o.status IN ('delivered', 'paid', 'completed', 'shipped')) AS total_revenue, " +
            "(SELECT COALESCE(SUM(oi.quantity * (p.price - p.p_price)), 0) " +
            " FROM order_items oi " +
            " JOIN products p ON p.id = oi.product_id " +
            " JOIN orders o ON o.id = oi.order_id " +
            " WHERE o.status IN ('delivered', 'paid', 'completed', 'shipped')) AS total_profit"
        ).getSingleResult();
        
        return (Object[]) result;
    }
}