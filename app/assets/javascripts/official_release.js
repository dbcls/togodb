(function() {
    const request_btn = document.getElementById("togodb-official-release-request-btn");

    const send_wrapper = document.getElementById("official-release-wrapper");
    const send_btn = document.getElementById("togodb-official-release-send-btn");

    const send_request = async () => {
        const email_element = document.getElementById("togodb-official-release-request-email");
        const body = {
            user_id: user_id,
            email: email_element.value
        }

        const response = await fetch(`/config/${table_id}/request_official`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=utf-8'
            },
            body: JSON.stringify(body)
        });

        if (response.ok) {
            const json = await response.json();
            if (json['status'] === "success") {
                const environment_elem = document.getElementById("togodb-database-environment");
                // environment_elem.style.paddingTop = "4px;";
                environment_elem.innerHTML = json['environment'];
            }
        } else {
            alert("HTTP-Error: " + response.status);
        }
    };

    request_btn.addEventListener("click", () => {
        console.log("request button is clicked.");
        send_wrapper.style.display = "flex";
    });

    send_btn.addEventListener("click", () => {
        console.log("send button is clicked.");
        send_wrapper.style.display = "none";
        send_request();
    });
})();
