import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { fetchWithAuth, postWithAuth } from '../utils/api';

export default function TaskDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { getToken } = useAuth();
  const [task, setTask] = useState(null);
  const [stats, setStats] = useState(null);
  const [checkins, setCheckins] = useState([]);
  const [loading, setLoading] = useState(true);
  const [checkingIn, setCheckingIn] = useState(false);
  const [message, setMessage] = useState('');

  useEffect(() => {
    const token = getToken();
    Promise.all([
      fetchWithAuth(getToken, `/api/tasks/${id}`),
      fetchWithAuth(getToken, `/api/checkins/stats/${id}`),
      fetchWithAuth(getToken, `/api/checkins/${id}`),
    ])
      .then(([t, s, c]) => {
        setTask(t);
        setStats(s);
        setCheckins(c);
      })
      .catch(console.error)
      .finally(() => setLoading(false));
  }, [id, getToken]);

  async function handleCheckin() {
    setCheckingIn(true);
    setMessage('');
    try {
      const result = await postWithAuth(getToken, `/api/checkins/${id}`, {});
      setMessage(`打卡成功！获得 ${result.points} 积分（连续 ${result.streak} 天）`);
      // Refresh
      const [s, c] = await Promise.all([
        fetchWithAuth(getToken, `/api/checkins/stats/${id}`),
        fetchWithAuth(getToken, `/api/checkins/${id}`),
      ]);
      setStats(s);
      setCheckins(c);
    } catch (err) {
      setMessage(err.message);
    } finally {
      setCheckingIn(false);
    }
  }

  if (loading) return <div className="loading">加载中...</div>;
  if (!task) return <div className="loading">任务不存在</div>;

  return (
    <div>
      <button className="btn btn-default" onClick={() => navigate('/')} style={{ marginBottom: 16 }}>← 返回</button>
      <div className="card">
        <h2>{task.title}</h2>
        <p style={{ color: '#666', marginTop: 8 }}>{task.description || '暂无描述'}</p>
        <div style={{ display: 'flex', gap: 24, marginTop: 16, fontSize: 14, color: '#999' }}>
          <span>创建者: {task.creator_name}</span>
          <span>开始: {task.start_date}</span>
          {task.end_date && <span>结束: {task.end_date}</span>}
        </div>
      </div>

      {stats && (
        <div className="card">
          <div className="checkin-header">
            <div className="checkin-points">{stats.total_points}</div>
            <div className="checkin-label">累计获得积分</div>
            <div style={{ marginTop: 8, color: '#999', fontSize: 14 }}>已打卡 {stats.total} 天</div>
            <div style={{ marginTop: 16 }}>
              <button
                className={`btn ${stats.checked_in_today ? 'btn-default' : 'btn-success'}`}
                onClick={handleCheckin}
                disabled={checkingIn || stats.checked_in_today}
                style={{ fontSize: 16, padding: '12px 32px' }}
              >
                {stats.checked_in_today ? '今日已打卡 ✓' : (checkingIn ? '打卡中...' : '今日打卡')}
              </button>
            </div>
            {message && (
              <div style={{ marginTop: 12, color: message.includes('成功') ? '#52c41a' : '#ff4d4f', fontSize: 14 }}>
                {message}
              </div>
            )}
          </div>
        </div>
      )}

      <div className="card">
        <div className="card-title">打卡记录</div>
        {checkins.length === 0 ? (
          <p style={{ color: '#999', textAlign: 'center', padding: 20 }}>暂无打卡记录</p>
        ) : (
          <div className="checkin-history">
            {checkins.map(c => (
              <div className="checkin-item" key={c.id}>
                <span className="checkin-date">{c.checkin_date}</span>
                <span className="checkin-pts">+{c.points} 分</span>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
