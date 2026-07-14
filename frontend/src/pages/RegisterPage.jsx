import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

export default function RegisterPage() {
  const { register, user } = useAuth();
  const navigate = useNavigate();
  const [form, setForm] = useState({ username: '', password: '', nickname: '' });
  const [error, setError] = useState('');

  if (user) { navigate('/', { replace: true }); return null; }

  async function handleSubmit(e) {
    e.preventDefault();
    setError('');
    try {
      await register(form.username, form.password, form.nickname);
      navigate('/');
    } catch (err) {
      setError(err.message);
    }
  }

  return (
    <div className="auth-page">
      <div className="auth-card">
        <h1>学习打卡激励系统</h1>
        <p className="subtitle">创建新账号</p>
        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label>用户名</label>
            <input value={form.username} onChange={e => setForm({ ...form, username: e.target.value })} required />
          </div>
          <div className="form-group">
            <label>昵称</label>
            <input value={form.nickname} onChange={e => setForm({ ...form, nickname: e.target.value })} required />
          </div>
          <div className="form-group">
            <label>密码</label>
            <input type="password" value={form.password} onChange={e => setForm({ ...form, password: e.target.value })} required />
          </div>
          {error && <div className="form-error">{error}</div>}
          <button type="submit" className="btn btn-primary" style={{ width: '100%', marginTop: 8 }}>注册</button>
        </form>
        <div className="auth-link">已有账号？<Link to="/login">登录</Link></div>
      </div>
    </div>
  );
}
