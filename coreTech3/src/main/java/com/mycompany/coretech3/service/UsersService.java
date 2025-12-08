/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.mycompany.coretech3.service;

import com.mycompany.coretech3.model.Users;
import com.mycompany.coretech3.security.JwtUtil;
import java.util.Date;
import java.util.List;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.ParameterMode;
import javax.persistence.StoredProcedureQuery;
import org.json.JSONArray;
import org.json.JSONObject;
import org.mindrot.jbcrypt.BCrypt;

@Stateless
public class UsersService {

    @PersistenceContext(unitName = "com.mycompany_coreTech3_war_1.0-SNAPSHOTPU")
    private EntityManager em;

    public JSONObject createUser(String username, String email, String phone, String password, String role) {
        JSONObject resp = new JSONObject();

        try {
            String hashedPw = BCrypt.hashpw(password, BCrypt.gensalt(12));

            if (role == null || role.trim().isEmpty()) {
                role = "customer";
            }

            StoredProcedureQuery query = em.createStoredProcedureQuery("createUser");

            query.registerStoredProcedureParameter("usernIN", String.class, ParameterMode.IN);
            query.registerStoredProcedureParameter("emailIN", String.class, ParameterMode.IN);
            query.registerStoredProcedureParameter("phoneIN", String.class, ParameterMode.IN);
            query.registerStoredProcedureParameter("passwIN", String.class, ParameterMode.IN);
            query.registerStoredProcedureParameter("roleIN", String.class, ParameterMode.IN);

            query.setParameter("usernIN", username);
            query.setParameter("emailIN", email);
            query.setParameter("phoneIN", phone);
            query.setParameter("passwIN", hashedPw);
            query.setParameter("roleIN", role);

            query.execute();

            EmailService.sendEmail(
                    email,
                    "Sikeres regisztráció ✔",
                    "<h1>Üdv a CoreTech-ben, " + username + "!</h1><p>A regisztrációd sikeres.</p>"
            );

            resp.put("status", "UserCreated");
            resp.put("statusCode", 201);

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
        }

        return resp;
    }

    public JSONObject softDeleteUser(int userId) {
        JSONObject resp = new JSONObject();

        try {
            // 1) user betöltése
            Users user = em.find(Users.class, userId);
            if (user == null) {
                resp.put("status", "UserNotFound");
                resp.put("statusCode", 404);
                return resp;
            }

            String email = user.getEmail();
            String username = user.getUsername();

            // 2) stored procedure hívása
            StoredProcedureQuery spq = em.createStoredProcedureQuery("softDelUser");
            spq.registerStoredProcedureParameter("userIDIN", Integer.class, ParameterMode.IN);
            spq.setParameter("userIDIN", userId);

            spq.execute();

            // 3) Email küldés
            EmailService.sendEmail(
                    email,
                    "Fiók deaktiválva ✔",
                    "<h1>Szia " + username + "!</h1>"
                    + "<p>A fiókod sikeresen deaktiválva lett.</p>"
                    + "<p>Ha nem te voltál, azonnal vedd fel velünk a kapcsolatot!</p>"
            );

            resp.put("status", "UserSoftDeleted");
            resp.put("statusCode", 200);

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
        }

        return resp;
    }

    public JSONObject updateUser(int userId, String email, String phone) {
        JSONObject resp = new JSONObject();

        try {
            // betöltjük a usert (emailhez kell)
            Users user = em.find(Users.class, userId);
            if (user == null) {
                resp.put("status", "UserNotFound");
                resp.put("statusCode", 404);
                return resp;
            }

            String oldEmail = user.getEmail();
            String username = user.getUsername();

            StoredProcedureQuery spq = em.createStoredProcedureQuery("updateUserById");

            spq.registerStoredProcedureParameter("userIdIN", Integer.class, ParameterMode.IN);
            spq.registerStoredProcedureParameter("usernameIN", String.class, ParameterMode.IN);
            spq.registerStoredProcedureParameter("emailIN", String.class, ParameterMode.IN);
            spq.registerStoredProcedureParameter("roleIN", String.class, ParameterMode.IN);

            spq.setParameter("userIdIN", userId);
            spq.setParameter("usernameIN", username);
            spq.setParameter("emailIN", email);
            spq.setParameter("roleIN", user.getRole());

            spq.execute();

            // EMAIL
            EmailService.sendEmail(
                    oldEmail,
                    "Fiók módosítva ✔",
                    "<h1>Szia " + username + "!</h1>"
                    + "<p>A fiók adataid frissítve lettek.</p>"
            );

            resp.put("status", "UserUpdated");
            resp.put("statusCode", 200);

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
        }

        return resp;
    }

    public JSONObject updatePassword(int userId, String newPassword) {
        JSONObject resp = new JSONObject();

        try {
            Users user = em.find(Users.class, userId);
            if (user == null) {
                resp.put("status", "UserNotFound");
                resp.put("statusCode", 404);
                return resp;
            }

            String email = user.getEmail();
            String username = user.getUsername();

            String hashed = BCrypt.hashpw(newPassword, BCrypt.gensalt(12));

            StoredProcedureQuery spq = em.createStoredProcedureQuery("updatePassword");

            spq.registerStoredProcedureParameter("userIdIN", Integer.class, ParameterMode.IN);
            spq.registerStoredProcedureParameter("passwordIN", String.class, ParameterMode.IN);

            spq.setParameter("userIdIN", userId);
            spq.setParameter("passwordIN", hashed);

            spq.execute();

            EmailService.sendEmail(
                    email,
                    "Jelszó frissítve ✔",
                    "<h1>Szia " + username + "!</h1>"
                    + "<p>A jelszavad sikeresen frissült!</p>"
            );

            resp.put("status", "PasswordUpdated");
            resp.put("statusCode", 200);

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
        }

        return resp;
    }

    public JSONObject getOrdersByUserId(int userId) {
        JSONObject resp = new JSONObject();

        try {
            StoredProcedureQuery spq = em.createStoredProcedureQuery("getOrdersByUserId");
            spq.registerStoredProcedureParameter("userIdIN", Integer.class, ParameterMode.IN);
            spq.setParameter("userIdIN", userId);

            List<Object[]> rows = spq.getResultList();
            JSONArray arr = new JSONArray();

            for (Object[] row : rows) {
                JSONObject obj = new JSONObject();

                obj.put("orderId", row[0]);
                obj.put("productName", row[1]);
                obj.put("imageUrl", row[2]);
                obj.put("totalPrice", row[3]);
                obj.put("status", row[4]);
                obj.put("quantity", row[5]);
                obj.put("createdAt", row[6]);

                arr.put(obj);
            }

            resp.put("orders", arr);
            resp.put("status", "Success");
            resp.put("statusCode", 200);

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
        }

        return resp;
    }

    public JSONObject login(String email, String password) {
        JSONObject resp = new JSONObject();

        try {
            StoredProcedureQuery spq = em.createStoredProcedureQuery("login");

            spq.registerStoredProcedureParameter("emailIN", String.class, ParameterMode.IN);
            spq.setParameter("emailIN", email);

            spq.execute();

            List<Object> rows = spq.getResultList();

            if (rows == null || rows.isEmpty()) {
                resp.put("status", "InvalidEmailOrPassword");
                resp.put("statusCode", 401);
                return resp;
            }

            String storedHash = rows.get(0).toString();

            if (!BCrypt.checkpw(password, storedHash)) {
                resp.put("status", "InvalidEmailOrPassword");
                resp.put("statusCode", 401);
                return resp;
            }

            String token = JwtUtil.generateToken(email);

            resp.put("status", "LoginSuccess");
            resp.put("statusCode", 200);
            resp.put("token", token);

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
        }

        return resp;
    }
}

