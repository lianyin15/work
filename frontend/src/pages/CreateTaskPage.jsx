import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { fetchWithAuth } from '../utils/api';

export default function CreateTaskPage() {
  const { getToken } = useAuth();
  const navigate = useNavigate();
  const [form, setForm] = useState({ title: '', description: '', start_date: '', end_date: '' });
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  async function handleSubmit(e) {
    e.preventDefault();
    if (!form.title || !form.start_date) {
      setError('标题和开始日期必填');
      return;
    }
    setSubmitting(true);
    setError('');
    try {
      const token = getToken();
      const res = await fetch('/api/tasks', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify(form),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || '创建失败');
      navigate(`/tasks/${data.id}`);
    } catch (err) {
      setError(err.message);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div>
      <h2 style={{ marginBottom: 20 }}>创建打卡任务</h2>
      <div className="card">
        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label>任务标题 *</label>
            <input value={form.title} onChange={e => setForm({ ...form, title: e.target.value })} placeholder="如：每天复习高数" required />
          </div>
          <div className="form-group">
            <label>任务描述</label>
            <textarea value={form.description} onChange={e => setForm({ ...form, description: e.target.value })} placeholder="描述你的打卡目标..." />
          </div>
          <div className="form-group">
            <label>开始日期 *</label>
            <input type="date" value={form.start_date} onChange={e => setForm({ ...form, start_date: e.target.value })} required />
          </div>
          <div className="form-group">
            <label>结束日期（可选）</label>
            <input type="date" value={form.end_date} onChange={e => setForm({ ...form, end_date: e.target.value })} />
          </div>
          {error && <div className="form-error">{error}</div>}
          <div className="form-actions">
            <button type="submit" className="btn btn-primary" disabled={submitting}>
              {submitting ? '创建中...' : '创建任务'}
            </button>
            <button type="button" className="btn btn-default" onClick={() => navigate('/')}>取消</button>
          </div>
        </form>
      </div>
    </div>
  );
}
