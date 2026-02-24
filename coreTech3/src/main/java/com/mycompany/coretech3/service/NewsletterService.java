/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.mycompany.coretech3.service;


import com.mycompany.coretech3.model.Users;
import com.mycompany.coretech3.util.EmailTemplateLoader;
import java.util.List;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.ParameterMode;
import javax.persistence.StoredProcedureQuery;
import org.json.JSONArray;
import org.json.JSONObject;

@Stateless
public class NewsletterService {

    @PersistenceContext(unitName = "com.mycompany_coreTech3_war_1.0-SNAPSHOTPU")
    private EntityManager em;

    // Template file names mapped to types
    private String getTemplateFile(String type) {
        switch (type) {
            case "welcome":
                return "newsletter_welcome.html";
            case "new_arrivals":
                return "newsletter_new_arrivals.html";
            case "promotion":
                return "newsletter_summer_sale.html";
            case "vip_exclusive":
                return "newsletter_vip_exclusive.html";
            default:
                return null;
        }
    }

    // Template subjects mapped to types
    private String getTemplateSubject(String type) {
        switch (type) {
            case "welcome":
                return "Üdvözlünk a CoreTech-nél!";
            case "new_arrivals":
                return "Új termékek érkeztek!";
            case "promotion":
                return "Nyári Akció - Akár 40% kedvezmény!";
            case "vip_exclusive":
                return "Exkluzív ajánlatok csak neked!";
            default:
                return "CoreTech Hírlevél";
        }
    }

    public JSONObject subscribeToNewsletter(String email) {
        JSONObject resp = new JSONObject();

        try {
            // 1. Find user by email
            Users user = em.createQuery("SELECT u FROM Users u WHERE u.email = :email AND u.isDeleted = 0", Users.class)
                    .setParameter("email", email)
                    .getSingleResult();

            // 2. Check if already subscribed
            if (user.getIsSubscripted() != null && user.getIsSubscripted() == true) {
                resp.put("status", "AlreadySubscribed");
                resp.put("message", "Már feliratkoztál a hírlevélre!");
                resp.put("statusCode", 409);
                return resp;
            }

            // 3. Set is_subscripted to 1
            user.setIsSubscripted(true);
            em.merge(user);

            // 4. Send welcome email
            String template = EmailTemplateLoader.loadTemplate("subscribe_welcome.html");
            template = template.replace("{{username}}", user.getUsername());

            EmailService.sendEmail(email, "Üdvözlünk a CoreTech hírlevelében!", template);

            resp.put("status", "Subscribed");
            resp.put("message", "Sikeresen feliratkoztál!");
            resp.put("statusCode", 200);

        } catch (javax.persistence.NoResultException e) {
            resp.put("status", "UserNotFound");
            resp.put("message", "Ez az email cím nincs regisztrálva.");
            resp.put("statusCode", 404);
        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "Error");
            resp.put("message", "Hiba történt: " + e.getMessage());
            resp.put("statusCode", 500);
        }

        return resp;
    }

   
    public JSONObject sendNewsletter(String type) {
        JSONObject resp = new JSONObject();

        try {
            // 1. Load the HTML template
            String templateFile = getTemplateFile(type);
            if (templateFile == null) {
                resp.put("status", "InvalidType");
                resp.put("message", "Érvénytelen hírlevél típus: " + type);
                resp.put("statusCode", 400);
                return resp;
            }

            String htmlContent = EmailTemplateLoader.loadTemplate(templateFile);
            if (htmlContent == null) {
                resp.put("status", "TemplateError");
                resp.put("message", "A sablon nem található: " + templateFile);
                resp.put("statusCode", 500);
                return resp;
            }

            String subject = getTemplateSubject(type);

           
            StoredProcedureQuery userQuery = em.createStoredProcedureQuery("getSubscribedUsers");
            userQuery.execute();
            List<Object[]> subscribers = userQuery.getResultList();

            if (subscribers.isEmpty()) {
                resp.put("status", "NoSubscribers");
                resp.put("message", "Nincsenek feliratkozott felhasználók.");
                resp.put("statusCode", 404);
                return resp;
            }

            
            StoredProcedureQuery insertQuery = em.createStoredProcedureQuery("createNewsletter");
            insertQuery.registerStoredProcedureParameter("subjectIN", String.class, ParameterMode.IN);
            insertQuery.registerStoredProcedureParameter("contentIN", String.class, ParameterMode.IN);
            insertQuery.registerStoredProcedureParameter("typeIN", String.class, ParameterMode.IN);
            insertQuery.setParameter("subjectIN", subject);
            insertQuery.setParameter("contentIN", htmlContent);
            insertQuery.setParameter("typeIN", type);
            insertQuery.execute();

           
            int sentCount = 0;
            int failCount = 0;

            for (Object[] row : subscribers) {
                String username = (String) row[1];
                String email = (String) row[2];

                try {
                    // Personalize: replace {{username}} if it exists in template
                    String personalizedHtml = htmlContent.replace("{{username}}", username);

                    EmailService.sendEmail(email, subject, personalizedHtml);
                    sentCount++;
                    System.out.println("✔ Hírlevél elküldve: " + email);
                } catch (Exception e) {
                    failCount++;
                    System.err.println("❌ Hírlevél hiba: " + email + " - " + e.getMessage());
                }
            }

          
            resp.put("status", "NewsletterSent");
            resp.put("message", "Hírlevél sikeresen elküldve!");
            resp.put("type", type);
            resp.put("totalSubscribers", subscribers.size());
            resp.put("sent", sentCount);
            resp.put("failed", failCount);
            resp.put("statusCode", 200);

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "Error");
            resp.put("message", "Hiba történt: " + e.getMessage());
            resp.put("statusCode", 500);
        }

        return resp;
    }

    /**
     * Get all sent newsletters (history)
     */
    public JSONObject getAllNewsletters() {
        JSONObject resp = new JSONObject();

        try {
            StoredProcedureQuery query = em.createStoredProcedureQuery("getAllNewsletters");
            query.execute();
            List<Object[]> results = query.getResultList();

            JSONArray newsletters = new JSONArray();
            for (Object[] row : results) {
                JSONObject nl = new JSONObject();
                nl.put("id", row[0]);
                nl.put("subject", row[1]);
                nl.put("type", row[2]);
                nl.put("created_at", row[3] != null ? row[3].toString() : null);
                nl.put("sent_at", row[4] != null ? row[4].toString() : null);
                newsletters.put(nl);
            }

            resp.put("status", "Success");
            resp.put("newsletters", newsletters);
            resp.put("statusCode", 200);

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "Error");
            resp.put("statusCode", 500);
        }

        return resp;
    }

    /**
     * Get all subscribed users
     */
    public JSONObject getSubscribers() {
        JSONObject resp = new JSONObject();

        try {
            StoredProcedureQuery query = em.createStoredProcedureQuery("getSubscribedUsers");
            query.execute();
            List<Object[]> results = query.getResultList();

            JSONArray users = new JSONArray();
            for (Object[] row : results) {
                JSONObject user = new JSONObject();
                user.put("id", row[0]);
                user.put("username", row[1]);
                user.put("email", row[2]);
                users.put(user);
            }

            resp.put("status", "Success");
            resp.put("subscribers", users);
            resp.put("count", results.size());
            resp.put("statusCode", 200);

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "Error");
            resp.put("statusCode", 500);
        }

        return resp;
    }
}
