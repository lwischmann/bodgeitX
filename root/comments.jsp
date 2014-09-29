<%@ page import="java.sql.*" %>

<%@ include file="/dbconnection.jspf" %>
<jsp:include page="/header.jsp"/>

<%
String username = (String) session.getAttribute("username");
String usertype = (String) session.getAttribute("usertype");

String comments = (String) request.getParameter("comments");
%>
<h3>Your comments</h3>
Please see what other users think about this amazing site. Please be free to add your feedback or comments here... <br/><br/>
<form method="POST">
	<input type="hidden" id="user" name="<%=username%>" value=""/>
	<center>
	<table>
	<tr>
		<td><textarea id="comments" name="comments" cols=80 rows=8></textarea></td>
	</tr>
	<tr>
		<td><input id="submit" type="submit" value="Submit"></input></td>
	</tr>
	</table>
	</center>
</form>
<%
if (comments != null) {

		PreparedStatement stmt = conn.prepareStatement("INSERT INTO Comments (name, comment) VALUES (?, ?)");
		ResultSet rs = null;
		try {
			stmt.setString(1, username);
			stmt.setString(2, comments);
			stmt.execute();

			if (username == null) {
				username = "Guest user";
			}

			out.println("<br/><p style=\"color:green\">Thank you for your feedback:</p><br/>");
			out.println("<br/><center><table border=\"1\" width=\"80%\" class=\"border\">");
			out.println("<tr><td>" + comments + "</td></tr>");
			out.println("</table></center><br/>");

			return;

		} catch (SQLException e) {
			out.println("System error.<br/><br/>" + e);
		} catch (Exception e) {
			out.println("System error.<br/><br/>" + e);
		} finally {
			stmt.close();
		}
}	// Display all of the messages
	ResultSet rs = null;
	PreparedStatement  stmt = conn.prepareStatement("SELECT * FROM Comments");
	try {
		rs = stmt.executeQuery();
		out.println("<br/><center><table border=\"1\" width=\"80%\" class=\"border\">");
		out.println("<tr><th></th><th>Comment</th></tr>");
		while (rs.next()) {
			out.println("<tr>");
			out.println("<td>guest</td><td>" + rs.getString("comment") + "</td>");
			out.println("</tr>");
		}
		out.println("</table></center><br/>");
	} catch (Exception e) {
			out.println("System error.");
	} finally {
		stmt.close();
	}

	// Display the message form
%>

<jsp:include page="/footer.jsp"/>


