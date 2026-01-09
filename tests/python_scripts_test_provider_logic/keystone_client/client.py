from openstack import connection 

AUTH_URL = "http://localhost:5000/v3"
USERNAME = "s4t-platform"
PASSWORD = "platform-secret"
USER_DOMAIN = "default"
PROJECT_DOMAIN = "default"
FEDERATED_DOMAIN = "federated_domain"
REGION = "RegionOne"

ROLES = [
    "admin_iot_project",
    "manager_iot_project",
    "user_iot"
]

def connect_to_keystone() -> connection.Connection:
    return connection.Connection(
        region_name=REGION,
        auth={
            "auth_url": AUTH_URL,
            "username": "s4t-platform",
            "password": "platform-secret",
            "user_domain_name": USER_DOMAIN,
            "domain_name": USER_DOMAIN,   #
        },
        identity_api_version="3",
    )

def get_or_create_project(conn: connection.Connection, project_name: str):
    project = conn.identity.find_project(project_name)
    if not project:
        project = conn.identity.create_project(
            name=project_name,
            domain_id="default"
        )
    print(f"Project: {project.name} (ID: {project.id})")
    return project

def get_or_create_groups(conn: connection.Connection, project_name):
    groups =[]
    derived_groups = [
        f"s4t:{project_name}:admin_iot_project",
        f"s4t:{project_name}:manager_iot_project",
        f"s4t:{project_name}:user_iot",
    ]
    for group in derived_groups:
        g = conn.identity.find_group(group, domain_id="default")
        if not g:
            g = conn.identity.create_group(
            name=group,
            domain_id="default",
        )
        groups.append(g)
        print(f"Group: {g.name} (ID: {g.id})")
    
    return groups
    
def get_s4t_roles(conn: connection.Connection):
    roles = []
    for r in ROLES:
        role = conn.identity.find_role(r)
        roles.append(role)
    return roles

def assign_role_to_groups(conn: connection.Connection, groups, roles, project):
    for g, role in zip(groups, roles):
        if not conn.identity.validate_group_has_project_role(g, project, role):
            conn.identity.assign_project_role_to_group(project, g, role)
            print(f"Ruolo '{role.name}' assegnato al gruppo '{g.name}' sul progetto '{project.name}'")
        else:
            print(f"Il gruppo '{g.name}' ha già il ruolo '{role.name}' sul progetto '{project.name}'")


class KeystoneClient:
    def __init__(self):
        self.connection = connect_to_keystone()

    def create_s4t_project_and_groups(self, projectName):
        project = get_or_create_project(self.connection, projectName)
        roles = get_s4t_roles(self.connection)
        groups = get_or_create_groups(self.connection, project_name=projectName)
        assign_role_to_groups(self.connection, groups, roles, project)