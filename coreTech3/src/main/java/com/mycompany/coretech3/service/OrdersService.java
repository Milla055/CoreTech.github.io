/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.mycompany.coretech3.service;

/**
 *
 * @author kamil
 */
import com.mycompany.coretech3.model.Orders;
import com.mycompany.coretech3.model.Users;
import java.util.List;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import org.json.JSONObject;

import javax.persistence.StoredProcedureQuery;

import javax.persistence.ParameterMode;
import org.json.JSONArray;

@Stateless
public class OrdersService {

    @PersistenceContext(unitName = "com.mycompany_coreTech3_war_1.0-SNAPSHOTPU")
    private EntityManager em;

    public JSONObject createOrder(int userId, int addressId, String totalPrice, String status) {
        JSONObject resp = new JSONObject();

        try {
            // 1) user adatok lekérése emailhez
            Users user = em.find(Users.class, userId);

            if (user == null) {
                resp.put("status", "UserNotFound");
                resp.put("statusCode", 404);
                return resp;
            }

            String email = user.getEmail();
            String username = user.getUsername();

            // 2) Stored procedure meghívás
            StoredProcedureQuery spq = em.createStoredProcedureQuery("createOrders");

            spq.registerStoredProcedureParameter("userIdIN", Integer.class, ParameterMode.IN);
            spq.registerStoredProcedureParameter("addressIdIN", Integer.class, ParameterMode.IN);
            spq.registerStoredProcedureParameter("totalpriceIN", String.class, ParameterMode.IN);
            spq.registerStoredProcedureParameter("statusIN", String.class, ParameterMode.IN);

            spq.setParameter("userIdIN", userId);
            spq.setParameter("addressIdIN", addressId);
            spq.setParameter("totalpriceIN", totalPrice);
            spq.setParameter("statusIN", status);

            spq.execute();

            // 3) Email küldése
            EmailService.sendEmail(
                    email,
                    "Rendelés leadva ✔",
                    "<h1>Szia " + username + "!</h1>"
                    + "<p>A rendelésed sikeresen leadásra került.</p>"
                    + "<p><b>Végösszeg:</b> " + totalPrice + " Ft</p>"
                    + "<p>Státusz: " + status + "</p>"
            );

            // 4) Válasz
            resp.put("status", "OrderCreated");
            resp.put("statusCode", 201);

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
        }

        return resp;
    }

    public void autoProgressOrders() {
    try {
        List<Orders> orders = em.createQuery(
            "SELECT o FROM Orders o WHERE o.status <> 'delivered'", Orders.class
        ).getResultList();

        for (Orders o : orders) {

            String newStatus;

            switch (o.getStatus()) {
                case "pending":
                    newStatus = "fizetve!";
                    break;
                case "paid":
                    newStatus = "kiszállítás alatt.";
                    break;
                case "shipped":
                    newStatus = "kiszállítva!";
                    break;
                default:
                    newStatus = o.getStatus();
                    break;
            }

            if (!newStatus.equals(o.getStatus())) {

                o.setStatus(newStatus);
                em.merge(o);

                EmailService.sendEmail(
                    o.getUserId().getEmail(),
                    "Rendelés státusz frissítve ✔",
                    "<h1>Új státusz: " + newStatus + "</h1>"
                );
            }
        }

    } catch (Exception e) {
        e.printStackTrace();
    }
}
    public JSONObject getOrdersByUserId(int userId) {
    JSONObject resp = new JSONObject();

    try {
        StoredProcedureQuery spq = em.createStoredProcedureQuery("getOrdersByUserId");

        spq.registerStoredProcedureParameter("userIdIN", Integer.class, ParameterMode.IN);
        spq.setParameter("userIdIN", userId);

        List<Object[]> results = spq.getResultList();

        JSONArray ordersArray = new JSONArray();

        for (Object[] row : results) {
            JSONObject order = new JSONObject();

            order.put("order_id", row[0]);
            order.put("product_name", row[1]);
            order.put("image_url", row[2]);
            order.put("total_price", row[3]);
            order.put("status", row[4]);
            order.put("quantity", row[5]);
            order.put("created_at", row[6]);

            ordersArray.put(order);
        }

        resp.put("status", "OK");
        resp.put("statusCode", 200);
        resp.put("orders", ordersArray);

    } catch (Exception e) {
        e.printStackTrace();
        resp.put("status", "DatabaseError");
        resp.put("statusCode", 500);
    }

    return resp;
}



}

