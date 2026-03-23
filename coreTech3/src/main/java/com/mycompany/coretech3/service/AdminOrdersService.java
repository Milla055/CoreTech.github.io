/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.mycompany.coretech3.service;

import com.mycompany.coretech3.model.Orders;
import com.mycompany.coretech3.model.Users;
import java.util.Date;
import java.util.List;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import org.json.JSONArray;
import org.json.JSONObject;

/**
 *
 * @author kamil
 */
@Stateless
public class AdminOrdersService {

    @PersistenceContext(unitName = "com.mycompany_coreTech3_war_1.0-SNAPSHOTPU")
    private EntityManager em;

    // ================================ GET ALL ORDERS ==================================
    public JSONObject getAllOrders() {
        JSONObject resp = new JSONObject();

        try {
            List<Orders> orders = em.createQuery("SELECT o FROM Orders o", Orders.class)
                    .getResultList();

            JSONArray arr = new JSONArray();

            for (Orders o : orders) {
                JSONObject obj = new JSONObject();
                obj.put("orderId", o.getId());
                obj.put("userId", o.getUserId().getId());
                obj.put("username", o.getUserId().getUsername());
                obj.put("totalPrice", o.getTotalPrice());
                obj.put("status", o.getStatus());
                obj.put("createdAt", o.getCreatedAt());

                arr.put(obj);
            }

            resp.put("status", "Success");
            resp.put("statusCode", 200);
            resp.put("orders", arr);

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
        }

        return resp;
    }

    // ================================ GET ORDER BY ID ==================================
    public JSONObject getOrderById(int orderId) {
        JSONObject resp = new JSONObject();

        try {
            Orders o = em.find(Orders.class, orderId);

            if (o == null) {
                resp.put("status", "NotFound");
                resp.put("statusCode", 404);
                return resp;
            }

            JSONObject obj = new JSONObject();
            obj.put("orderId", o.getId());
            obj.put("userId", o.getUserId().getId());
            obj.put("username", o.getUserId().getUsername());
            obj.put("totalPrice", o.getTotalPrice());
            obj.put("status", o.getStatus());
            obj.put("createdAt", o.getCreatedAt());

            resp.put("status", "Success");
            resp.put("statusCode", 200);
            resp.put("order", obj);

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
        }

        return resp;
    }

    // ================================ UPDATE STATUS ==================================
    public JSONObject updateOrderStatus(int orderId, String newStatus) {
        JSONObject resp = new JSONObject();

        try {
            Orders o = em.find(Orders.class, orderId);

            if (o == null) {
                resp.put("status", "NotFound");
                resp.put("statusCode", 404);
                return resp;
            }

            o.setStatus(newStatus);
            em.merge(o);

            resp.put("status", "StatusUpdated");
            resp.put("statusCode", 200);
            resp.put("newStatus", newStatus);

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
        }

        return resp;
    }

    // ================================ SOFT DELETE ORDER ==================================
    public JSONObject softDeleteOrder(int orderId) {
    JSONObject resp = new JSONObject();

    try {
        Orders o = em.find(Orders.class, orderId);

        if (o == null) {
            resp.put("status", "OrderNotFound");
            resp.put("statusCode", 404);
            return resp;
        }

        
        o.setIsDeleted((short) 1);          // tinyint → Short
        o.setDeletedAt(new java.util.Date());

        em.merge(o);

        resp.put("status", "OrderDeleted");
        resp.put("statusCode", 200);

    } catch (Exception e) {
        e.printStackTrace();
        resp.put("status", "DatabaseError");
        resp.put("statusCode", 500);
    }

    return resp;
}

    // ================================ GET ORDERS BY USER (ADMIN VIEW) ==================================
    public JSONObject getOrdersByUserAdmin(int userId) {
        JSONObject resp = new JSONObject();

        try {
            Users u = em.find(Users.class, userId);

            if (u == null) {
                resp.put("status", "UserNotFound");
                resp.put("statusCode", 404);
                return resp;
            }

            List<Orders> orders = em.createQuery(
                    "SELECT o FROM Orders o WHERE o.userId.id = :uid", Orders.class)
                    .setParameter("uid", userId)
                    .getResultList();

            JSONArray arr = new JSONArray();

            for (Orders o : orders) {
                JSONObject obj = new JSONObject();
                obj.put("orderId", o.getId());
                obj.put("totalPrice", o.getTotalPrice());
                obj.put("status", o.getStatus());
                obj.put("createdAt", o.getCreatedAt());

                arr.put(obj);
            }

            resp.put("status", "Success");
            resp.put("statusCode", 200);
            resp.put("orders", arr);

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
        }

        return resp;
    }
}
