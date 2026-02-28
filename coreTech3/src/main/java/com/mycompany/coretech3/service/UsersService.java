
package com.mycompany.coretech3.service;

import com.mycompany.coretech3.model.Users;
import com.mycompany.coretech3.security.JwtUtil;
import com.mycompany.coretech3.util.EmailTemplateLoader;
import java.util.List;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.NoResultException;
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
            query.registerStoredProcedureParameter("passwIN", String.class, ParameterMode.IN);
            query.registerStoredProcedureParameter("phoneIN", String.class, ParameterMode.IN);
            query.registerStoredProcedureParameter("roleIN", String.class, ParameterMode.IN);

            query.setParameter("usernIN", username);
            query.setParameter("emailIN", email);
            query.setParameter("passwIN", hashedPw);
            query.setParameter("phoneIN", phone);
            query.setParameter("roleIN", role);

            query.execute();

            String template = EmailTemplateLoader.loadTemplate("regEmail.html");
            template = template.replace("{{username}}", username);

            EmailService.sendEmailWithImage(
                    email,
                    "Sikeres Regisztráció!",
                    template,
                    "checkmark.png"
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

            String template = EmailTemplateLoader.loadTemplate("fiokdeakt.html");

            if (template != null) {
                template = template.replace("{{username}}", username);

                EmailService.sendEmailWithImage(
                        email,
                        "Sikeres Deaktiváció! ",
                        template,
                        "checkmark.png"
                );
            }

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
            spq.registerStoredProcedureParameter("phoneIN", String.class, ParameterMode.IN);

            spq.setParameter("userIdIN", userId);
            spq.setParameter("usernameIN", username);
            spq.setParameter("emailIN", email);
            spq.setParameter("roleIN", user.getRole());
            spq.setParameter("phoneIN", phone);

            spq.execute();

            String template = EmailTemplateLoader.loadTemplate("fiokmod.html");
            template = template.replace("{{username}}", username);

            EmailService.sendEmailWithImage(
                    email,
                    "Sikeres Modifikáció!",
                    template,
                    "checkmark.png"
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

    public JSONObject changePassword(int userId, String oldPassword, String newPassword) {
    JSONObject resp = new JSONObject();
    try {
        // 1) Load user from database
        Users user = em.find(Users.class, userId);
        if (user == null) {
            resp.put("status", "UserNotFound");
            resp.put("statusCode", 404);
            resp.put("message", "User not found");
            return resp;
        }
        
        // 2) Verify old password
        String storedPasswordHash = user.getPasswordHash();
        boolean isOldPasswordCorrect = BCrypt.checkpw(oldPassword, storedPasswordHash);
        
        if (!isOldPasswordCorrect) {
            resp.put("status", "Error");
            resp.put("statusCode", 401);
            resp.put("message", "Old password is incorrect");
            return resp;
        }
        
        // 3) Validate new password strength
        if (newPassword == null || newPassword.length() < 8) {
            resp.put("status", "WeakPassword");
            resp.put("statusCode", 400);
            resp.put("message", "Password must be at least 8 characters");
            return resp;
        }
        
        String email = user.getEmail();
        String username = user.getUsername();
        
        // 4) Hash the new password
        String hashed = BCrypt.hashpw(newPassword, BCrypt.gensalt(12));
        
        // 5) Call stored procedure to update password
        StoredProcedureQuery spq = em.createStoredProcedureQuery("updatePassword");
        spq.registerStoredProcedureParameter("userIdIN", Integer.class, ParameterMode.IN);
        spq.registerStoredProcedureParameter("passwordIN", String.class, ParameterMode.IN);
        
        spq.setParameter("userIdIN", userId);
        spq.setParameter("passwordIN", hashed);
        
        spq.execute();
        
        // 6) Send confirmation email
        String template = EmailTemplateLoader.loadTemplate("jelszofriss.html");
        if (template != null) {
            template = template.replace("{{username}}", username);
            EmailService.sendEmailWithImage(
                    email,
                    "Sikeres Jelszó Módosítás!",
                    template,
                    "checkmark.png"
            );
        }
        
        resp.put("status", "PasswordUpdated");
        resp.put("statusCode", 200);
        resp.put("message", "Password changed successfully");
        
    } catch (Exception e) {
        e.printStackTrace();
        resp.put("status", "DatabaseError");
        resp.put("statusCode", 500);
        resp.put("message", "Error changing password: " + e.getMessage());
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
        
        Object[] result = (Object[]) spq.getSingleResult();
        String storedHash = result[0].toString();
        String username = result[1].toString();
        String role = result[2].toString(); 
        
        if (!BCrypt.checkpw(password, storedHash)) {
            resp.put("status", "InvalidEmailOrPassword");
            resp.put("statusCode", 401);
            return resp;
        }
        
        Users user = em.createQuery(
                "SELECT u FROM Users u WHERE u.email = :email AND u.isDeleted = 0",
                Users.class
        )
                .setParameter("email", email)
                .getSingleResult();
        
        String accessToken = JwtUtil.generateAccessToken(
                user.getEmail(),
                user.getRole(),
                Long.valueOf(user.getId())
        );
        String refreshToken = JwtUtil.generateRefreshToken(
                Long.valueOf(user.getId())
        );
        
        resp.put("status", "LoginSuccess");
        resp.put("statusCode", 200);
        resp.put("accessToken", accessToken);
        resp.put("refreshToken", refreshToken);
        resp.put("username", username);
        resp.put("role", role); // ← ADD THIS
        
    } catch (NoResultException e) {
        resp.put("status", "InvalidEmailOrPassword");
        resp.put("statusCode", 401);
    } catch (Exception e) {
        e.printStackTrace();
        resp.put("status", "DatabaseError");
        resp.put("statusCode", 500);
    }
    return resp;
}
    public JSONObject updateUserProfile(int userId, String username, String fullName, String email, String phone) {
        JSONObject resp = new JSONObject();

        try {
            // 1) Felhasználó betöltése az adatbázisból - ellenőrizzük, hogy létezik-e
            Users user = em.find(Users.class, userId);
            if (user == null) {
                resp.put("status", "UserNotFound");
                resp.put("statusCode", 404);
                resp.put("message", "A felhasználó nem található");
                return resp;
            }

            // 2) Stored procedure hívása a profil frissítéséhez
            StoredProcedureQuery spq = em.createStoredProcedureQuery("updateUserProfile");

            spq.registerStoredProcedureParameter("userIdIN", Integer.class, ParameterMode.IN);
            spq.registerStoredProcedureParameter("usernameIN", String.class, ParameterMode.IN);
            spq.registerStoredProcedureParameter("teljesnevIN", String.class, ParameterMode.IN);
            spq.registerStoredProcedureParameter("emailIN", String.class, ParameterMode.IN);
            spq.registerStoredProcedureParameter("phoneIN", String.class, ParameterMode.IN);

            spq.setParameter("userIdIN", userId);
            spq.setParameter("usernameIN", username);
            spq.setParameter("teljesnevIN", fullName);
            spq.setParameter("emailIN", email);
            spq.setParameter("phoneIN", phone);

            spq.execute();

            // 3) Megerősítő email küldése (opcionális)
            String template = EmailTemplateLoader.loadTemplate("fiokmod.html");
            if (template != null) {
                template = template.replace("{{username}}", username);

                EmailService.sendEmailWithImage(
                        email,
                        "Profil Sikeresen Frissítve!",
                        template,
                        "checkmark.png"
                );
            }

            resp.put("status", "ProfileUpdated");
            resp.put("statusCode", 200);
            resp.put("message", "A profil sikeresen frissítve");

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", "Hiba történt a profil frissítése során: " + e.getMessage());
        }

        return resp;
    }

}
