<%@ page import="java.net.URL" %>
<%@ page import="java.servlet.http.*" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.math.*" %>
<%@ page import="java.text.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.text.*" %>

<%@ include file="/dbconnection.jspf" %>


<jsp:include page="/header.jsp"/>

<h3>Your Orders</h3>
<%
    String userid = (String) session.getAttribute("userid");
    String referrer = request.getHeader("referer");
    Cookie[] cookies = request.getCookies();
    String basketId = null;
    if (cookies != null) {
        for (Cookie cookie : cookies) {
            if (cookie.getName().equals("b_id") && cookie.getValue().length() > 0) {
                basketId = cookie.getValue();
                break;
            }
        }
    }

    out.println("<!-- Anti CSRF Mitigation:  Check if the referer contains the only valid source site. TBD: Security Review-->");
    if (request.getMethod().equals("POST") && referrer.contains("basket.jsp")) {

        Statement stmt = conn.createStatement();
        ResultSet rs = null;

        //Check for CSRF for Scoring by looking at the referrer
        URL url = new URL(referrer);
        if(!url.getFile().startsWith(request.getContextPath() + "/basket.jsp")){
            conn.createStatement().execute("UPDATE Score SET status = 1 WHERE task = 'CSRF_ORDER'");
        }


        try {


            rs = stmt.executeQuery("SELECT * FROM Users WHERE userid = " + userid + "");
            rs.next();
            int basketIdValue = rs.getInt("currentbasketid");
            if (basketIdValue > 0) {
                basketId = "" + basketIdValue;
            }

            if (basketId != null) {
                //create order
                String orderId = null;
                Timestamp ts = new Timestamp((new java.util.Date()).getTime());
                stmt.execute("INSERT INTO Orders (created, userid) VALUES ('" + ts + "', " + userid + ")");

                rs = stmt.executeQuery("SELECT * FROM Orders WHERE created = '" + ts + "' AND userid = '" + userid + "'");
                rs.next();
                orderId = "" + rs.getInt("orderid");

                rs = stmt.executeQuery("SELECT * FROM BasketContents WHERE basketid=" + basketId);

                while (rs.next()) {
                    stmt.execute("INSERT INTO OrderContents (orderid, productid, quantity, pricetopay) VALUES (" +
                            orderId + ", " + rs.getInt("productid") + ", " + rs.getInt("quantity") + ", " + rs.getDouble("pricetopay") + ")");


                }

                //Delete BasketContents and Basket
                stmt.execute("DELETE FROM BasketContents WHERE basketid='" + basketId + "'");
                stmt.execute("DELETE FROM Baskets WHERE basketid='" + basketId + "'");
                stmt.execute("UPDATE Users SET currentbasketid = null");

                //reset basket cookie
                response.addCookie(new Cookie("b_id", ""));

                out.println("You have successfully ordered the following Products:");
                out.println(getOrderTable(orderId));
                out.println("<a href='order.jsp'>Show all your orders.</a>");
            }
        } catch (SQLException e) {
            if ("true".equals(request.getParameter("debug"))) {
                conn.createStatement().execute("UPDATE Score SET status = 1 WHERE task = 'HIDDEN_DEBUG'");

                StringWriter sw = new StringWriter();
                PrintWriter pw = new PrintWriter(sw);
                e.printStackTrace(pw);

                out.println("DEBUG System error: " + sw.toString() + "<br/><br/>");
            } else {
                out.println("System error.");
            }
            return;

        } catch (Exception e) {
            if ("true".equals(request.getParameter("debug"))) {
                conn.createStatement().execute("UPDATE Score SET status = 1 WHERE task = 'HIDDEN_DEBUG'");

                StringWriter sw = new StringWriter();
                PrintWriter pw = new PrintWriter(sw);
                e.printStackTrace(pw);

                out.println("DEBUG System error: " + sw.toString() + "<br/><br/>");
            } else {
                out.println("System error.");
            }
            return;

        } finally {
            if (stmt != null) stmt.close();
        }
    } else {
        Statement stmt = conn.createStatement();
        ResultSet rs = null;

        try {
            rs = stmt.executeQuery("SELECT orderid, created FROM Orders WHERE userid = " + userid + " ORDER BY created DESC");
            while(rs.next())
            {
                out.println("<h4>" + new SimpleDateFormat("dd.MM.yyyy HH:mm").format(rs.getTimestamp("created")) + "</h4>");
                out.println(getOrderTable("" + rs.getInt("orderid")));
                out.println("<hr/>");
            }

        } catch (SQLException e) {
            if ("true".equals(request.getParameter("debug"))) {
                conn.createStatement().execute("UPDATE Score SET status = 1 WHERE task = 'HIDDEN_DEBUG'");

                StringWriter sw = new StringWriter();
                PrintWriter pw = new PrintWriter(sw);
                e.printStackTrace(pw);

                out.println("DEBUG System error: " + sw.toString() + "<br/><br/>");
            } else {
                out.println("System error.");
            }
            return;

        } catch (Exception e) {
            if ("true".equals(request.getParameter("debug"))) {
                conn.createStatement().execute("UPDATE Score SET status = 1 WHERE task = 'HIDDEN_DEBUG'");

                StringWriter sw = new StringWriter();
                PrintWriter pw = new PrintWriter(sw);
                e.printStackTrace(pw);

                out.println("DEBUG System error: " + sw.toString() + "<br/><br/>");
            } else {
                out.println("System error.");
            }
            return;

        } finally {
            if (stmt != null) stmt.close();
        }

    }
%>

<%!
    public String getOrderTable(String orderId) throws SQLException, Exception {
        Statement stmt = conn.createStatement();
        ResultSet rs = null;
        StringBuffer out = new StringBuffer();

        rs = stmt.executeQuery("SELECT * FROM OrderContents, Products WHERE orderid = " + orderId + " " +
                        " AND OrderContents.productid = Products.productid"
        );

        out.append("<table border=\"1\" class=\"border\" width=\"80%\">");
        out.append("<tr><th>Product</th><th>Quantity</th><th>Price</th><th>Total</th></tr>");
        BigDecimal orderTotal = new BigDecimal(0);
        NumberFormat nf = NumberFormat.getCurrencyInstance();
        while (rs.next()) {
            out.append("<tr>");
            String product = rs.getString("product");
            int prodId = rs.getInt("productid");
            BigDecimal pricetopay = rs.getBigDecimal("pricetopay");
            int quantity = rs.getInt("quantity");
            BigDecimal total = pricetopay.multiply(new BigDecimal(quantity));
            orderTotal = orderTotal.add(total);

            out.append("<td><a href=\"product.jsp?prodid=" + rs.getInt("productid") + "\">" + product + "</a></td>");
            out.append("<td style=\"text-align: center\">&nbsp;" + quantity + "</td>");
            out.append("<td align=\"right\">" + nf.format(pricetopay) + "</td>");
            out.append("</td><td align=\"right\">" + nf.format(total) + "</td>");
            out.append("</tr>");
        }
        out.append("<tr><td>Total</td><td style=\"text-align: center\"></td><td>&nbsp;</td>" +
                "<td align=\"right\">" + nf.format(orderTotal) + "</td></tr>");
        out.append("</table>");

        return out.toString();
    }
%>
<jsp:include page="/footer.jsp"/>

