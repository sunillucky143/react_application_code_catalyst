import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { postsApi } from '../services/api';
import { Save, Eye, EyeOff } from 'lucide-react';
import toast from 'react-hot-toast';

const Editor = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [isEditing, setIsEditing] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [showPreview, setShowPreview] = useState(false);
  const [post, setPost] = useState(null);

  const {
    register,
    handleSubmit,
    formState: { errors },
    setValue,
    watch,
  } = useForm({ defaultValues: { is_published: true } });

  const title = watch('title');
  const content = watch('content');

  useEffect(() => {
    if (id) {
      setIsEditing(true);
      fetchPost();
    }
  }, [id]);

  const fetchPost = async () => {
    try {
      const response = await postsApi.getById(id);
      const postData = response.data;
      setPost(postData);
      setValue('title', postData.title);
      setValue('content', postData.content);
      setValue('is_published', postData.is_published);
    } catch (error) {
      console.error('Error fetching post:', error);
      toast.error('Failed to load post');
      navigate('/');
    }
  };

  const onSubmit = async (data) => {
    setIsLoading(true);
    try {
      if (isEditing) {
        await postsApi.update(id, data);
        toast.success('Post updated successfully!');
      } else {
        await postsApi.create(data);
        toast.success('Post created successfully!');
      }
      navigate('/');
    } catch (error) {
      console.error('Error saving post:', error);
      toast.error('Failed to save post');
    } finally {
      setIsLoading(false);
    }
  };

  const renderPreview = () => {
    return (
      <div className="prose prose-lg max-w-none">
        <h1>{title || 'Untitled Post'}</h1>
        <div className="whitespace-pre-wrap">{content || 'Start writing your post...'}</div>
      </div>
    );
  };

  return (
    <div className="max-w-4xl mx-auto">
      <div className="mb-6 flex justify-between items-center">
        <h1 className="text-3xl font-bold text-gray-900">
          {isEditing ? 'Edit Post' : 'Create New Post'}
        </h1>
        <button
          onClick={() => setShowPreview(!showPreview)}
          className="btn btn-outline btn-sm"
        >
          {showPreview ? (
            <>
              <EyeOff className="w-4 h-4 mr-1" />
              Hide Preview
            </>
          ) : (
            <>
              <Eye className="w-4 h-4 mr-1" />
              Show Preview
            </>
          )}
        </button>
      </div>

      <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
        <div className="card">
          <div className="card-content">
            <div className="space-y-4">
              <div>
                <label htmlFor="title" className="block text-sm font-medium text-gray-700 mb-1">
                  Title
                </label>
                <input
                  id="title"
                  type="text"
                  className={`input ${errors.title ? 'border-red-500' : ''}`}
                  placeholder="Enter post title"
                  {...register('title', {
                    required: 'Title is required',
                    minLength: {
                      value: 3,
                      message: 'Title must be at least 3 characters',
                    },
                  })}
                />
                {errors.title && (
                  <p className="mt-1 text-sm text-red-600">{errors.title.message}</p>
                )}
              </div>

              <div>
                <label htmlFor="content" className="block text-sm font-medium text-gray-700 mb-1">
                  Content
                </label>
                <textarea
                  id="content"
                  rows={15}
                  className={`textarea ${errors.content ? 'border-red-500' : ''}`}
                  placeholder="Write your post content here... (Markdown supported)"
                  {...register('content', {
                    required: 'Content is required',
                    minLength: {
                      value: 10,
                      message: 'Content must be at least 10 characters',
                    },
                  })}
                />
                {errors.content && (
                  <p className="mt-1 text-sm text-red-600">{errors.content.message}</p>
                )}
              </div>

              <div className="flex items-center">
                <input
                  id="is_published"
                  type="checkbox"
                  className="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
                  defaultChecked={true}
                  {...register('is_published')}
                />
                <label htmlFor="is_published" className="ml-2 block text-sm text-gray-900">
                  Publish immediately
                </label>
              </div>
            </div>
          </div>
        </div>

        <div className="flex justify-end space-x-4">
          <button
            type="button"
            onClick={() => navigate('/')}
            className="btn btn-outline"
          >
            Cancel
          </button>
          <button
            type="submit"
            disabled={isLoading}
            className="btn btn-primary disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <Save className="w-4 h-4 mr-2" />
            {isLoading ? 'Saving...' : (isEditing ? 'Update Post' : 'Create Post')}
          </button>
        </div>
      </form>

      {showPreview && (
        <div className="mt-8 card">
          <div className="card-header">
            <h2 className="card-title">Preview</h2>
          </div>
          <div className="card-content">
            {renderPreview()}
          </div>
        </div>
      )}
    </div>
  );
};

export default Editor; 