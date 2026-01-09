from flask import Flask, request, jsonify
from keystone_client.client import KeystoneClient

class SimpleS4TProvider:

    def __init__(self):
        self.keystone_client = KeystoneClient()

    def create_project(self, projectName: str) -> bool:
        try:
            self.keystone_client.create_s4t_project_and_groups(projectName)
            return True
        except Exception as e:
            print(f"Errore nella creazione del progetto: {e}")
            return False

    def update_project(self) -> bool:
        #(todo): implement
        return False

    def delete_project(self) -> bool:
        #(todo): implement
        return False
    

service = Flask(__name__)
provider = SimpleS4TProvider()

@service.route("/create-project", methods=['POST'])
def create_project():
    data = request.get_json()
    if not data or "projectName" not in data:
        return jsonify({"success": False, "error": "projectName missing"}), 400

    project_name = data["projectName"]
    success = provider.create_project(project_name)

    if success:
        return jsonify({"success": True}), 200
    else:
        return jsonify({"success": False, "error": "Failed to create project"}), 500

@service.route("/update-project", methods=['POST'])
def update_project():
    return jsonify({"success": False, "error": "Failed to update project"}), 500

@service.route("/delete-project", methods=['POST'])
def delete_project():
    return jsonify({"success": False, "error": "Failed to delete project"}), 500

if __name__ == "__main__":
    service.run(host="0.0.0.0", port=8787)