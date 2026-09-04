const pool = require('../config/db');
const User = require('../models/userModel');

const getTenantId = (req) => {
    const tid = req.tenantId || req.headers['x-tenant-id'] || req.query.tenant_id || req.body.tenant_id;
    return tid ? parseInt(tid, 10) : null;
};

// 📌 GET ALL USERS (tenant-scoped)
const getAllUsers = async (req, res) => {
  try {
    const tenantId = getTenantId(req);
    const result = await User.getAll(tenantId);
    res.json(result.rows);
  } catch (err) {
    console.log(err);
    res.status(500).json({ message: "Server error" });
  }
};

// 📌 GET USER BY ID
const getUserById = async (req, res) => {
  try {
    const tenantId = getTenantId(req);
    const result = await User.getById(req.params.id, tenantId);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ message: "Server error" });
  }
};

// 📌 CREATE USER (tenant-scoped)
const createUser = async (req, res) => {
  try {
    const tenantId = getTenantId(req);
    const { username, password, role } = req.body;
    if (!username || !username.trim() || !password || !password.trim()) {
      return res.status(400).json({ message: "Geli Username iyo Password" });
    }
    const cleanUser = username.trim();
    const cleanPass = password.trim();
    const cleanRole = role || 'User';

    // Check duplicate username
    const existing = await pool.query('SELECT id FROM users WHERE LOWER(username) = LOWER($1)', [cleanUser]);
    if (existing.rows.length > 0) {
      return res.status(400).json({ message: "Username-kan hore ayaa loo isticmaalay!" });
    }

    const result = await User.create(cleanUser, cleanPass, cleanRole, tenantId);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.log("Create user error:", err.message);
    res.status(500).json({ message: "Server error: " + err.message });
  }
};

// 📌 UPDATE USER
const updateUser = async (req, res) => {
  try {
    const tenantId = getTenantId(req);
    const { username, password, role } = req.body;
    const result = await User.update(
      req.params.id,
      username,
      password,
      role,
      tenantId
    );
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ message: "Server error" });
  }
};

// 📌 DELETE USER
const deleteUser = async (req, res) => {
  try {
    const tenantId = getTenantId(req);
    await User.delete(req.params.id, tenantId);
    res.json({ message: "User deleted successfully" });
  } catch (err) {
    res.status(500).json({ message: "Server error" });
  }
};

// 📌 LOGIN USER (Supports Users table, Tenants Admin provisioned accounts, & SuperAdmin)
const loginUser = async (req, res) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({ message: "Geli Username iyo Password" });
    }

    const trimmedUser = username.trim();
    const trimmedPass = password.trim();
    const lowerUser = trimmedUser.toLowerCase();

    // 1. Check users table
    try {
      const userRes = await pool.query(
        'SELECT * FROM users WHERE LOWER(username) = LOWER($1) AND password = $2',
        [trimmedUser, trimmedPass]
      );
      if (userRes.rows.length > 0) {
        const foundUser = userRes.rows[0];

        // If user is missing tenant_id, auto-link if username matches tenant admin_username
        if (!foundUser.tenant_id) {
          const autoLink = await pool.query(
            'SELECT id, name FROM tenants WHERE LOWER(admin_username) = LOWER($1)',
            [trimmedUser]
          );
          if (autoLink.rows.length > 0) {
            const tenant = autoLink.rows[0];
            foundUser.tenant_id = tenant.id;
            foundUser.tenantName = tenant.name;
            await pool.query('UPDATE users SET tenant_id = $1 WHERE id = $2', [tenant.id, foundUser.id]).catch(() => {});
          }
        }

        // If user belongs to a tenant, check tenant status and attach tenantName
        if (foundUser.tenant_id) {
          const tenantCheck = await pool.query(
            'SELECT name, subscription_status, subscription_expires_at FROM tenants WHERE id = $1',
            [foundUser.tenant_id]
          );
          if (tenantCheck.rows.length > 0) {
            const tenant = tenantCheck.rows[0];
            if (tenant.subscription_status !== 'active' || (tenant.subscription_expires_at && new Date(tenant.subscription_expires_at) < new Date())) {
              return res.status(402).json({
                message: "Nidaamka iskuulkan waa ka dhacay waqtigii (Subscription Expired) ama waa la xiray. La xiriir Super Admin.",
                code: "SUBSCRIPTION_EXPIRED"
              });
            }
            foundUser.tenantName = tenant.name;
          }
        }

        return res.json({
          message: "Login success",
          user: foundUser
        });
      }
    } catch (dbErr) {
      console.log("Users query error:", dbErr.message);
    }

    // 2. Check tenants table directly (For provisioned school admins)
    try {
      const tenantRes = await pool.query(
        'SELECT * FROM tenants WHERE LOWER(admin_username) = LOWER($1) AND admin_password = $2',
        [trimmedUser, trimmedPass]
      );
      if (tenantRes.rows.length > 0) {
        const tenant = tenantRes.rows[0];
        if (tenant.subscription_status !== 'active' || (tenant.subscription_expires_at && new Date(tenant.subscription_expires_at) < new Date())) {
          return res.status(402).json({
            message: "Nidaamka iskuulkan waa ka dhacay waqtigii (Subscription Expired) ama waa la xiray. La xiriir Super Admin.",
            code: "SUBSCRIPTION_EXPIRED"
          });
        }

        return res.json({
          message: "Login success",
          user: {
            id: tenant.id,
            username: tenant.admin_username,
            role: "Admin",
            tenant_id: tenant.id,
            tenantName: tenant.name
          }
        });
      }
    } catch (tErr) {
      console.log("Tenants query error:", tErr.message);
    }

    // 3. Fallback SuperAdmin check
    if (
      (lowerUser === 'superadmin' && (trimmedPass === 'superadmin123' || trimmedPass === 'admin123' || trimmedPass === '123456')) ||
      (lowerUser === 'admin' && (trimmedPass === 'admin123' || trimmedPass === '123456'))
    ) {
      const fallbackRole = lowerUser === 'superadmin' ? 'SuperAdmin' : 'Admin';
      return res.json({
        message: "Login success",
        user: {
          id: 1,
          username: trimmedUser,
          role: fallbackRole
        }
      });
    }

    return res.status(401).json({ message: "Username ama Password waa khalad!" });

  } catch (err) {
    console.error("Login controller error:", err);
    res.status(500).json({ message: "Server error" });
  }
};

module.exports = {
  getAllUsers,
  getUserById,
  createUser,
  updateUser,
  deleteUser,
  loginUser
};