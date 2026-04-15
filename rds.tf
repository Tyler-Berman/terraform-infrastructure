resource "aws_db_instance" "MyRDS" {
    identifier = "first-rds"
    instance_class = "db.t2.micro"
    engine = "mariadb"
    engine_version = "10.2.21"
    username = ""
    password = ""
    port = 3306
    allocated_storage = 20
    skip_final_snapshot = true
    db_name = "My-First-RDS"
}