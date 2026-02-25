# Database Setup (phpMyAdmin)

1. Open `http://localhost/phpmyadmin`.
2. Click `Import`.
3. Choose file: `database/ocean_view_resort.sql`.
4. Click `Go`.

Default login users created by script:

- `admin` / `admin123`
- `staff` / `staff123`

If your MySQL root user has a password, update:

- `src/main/resources/config.properties`
- `src/main/webapp/admin/*.jsp` and `src/main/webapp/staff/*.jsp` database credential blocks (if needed)

